import {
  disableAll,
  isEnabledForTerminal,
  isStableBlockedSnapshot,
  isSupportedAgent,
  normalizeAgent,
  toggleGlobal,
  togglePane,
} from "./domain.mjs";
import { Herdr } from "./herdr.mjs";
import { waitForApprovalInspection } from "./inspect.mjs";
import { StateStore } from "./state-store.mjs";

const herdr = new Herdr();
const stateStore = new StateStore(process.env.HERDR_PLUGIN_STATE_DIR);
const MAX_CHAINED_APPROVALS = 8;
const FOLLOW_UP_MAX_ATTEMPTS = 200;

await main().catch(async (error) => {
  console.error(error?.stack ?? error);
  if (process.argv[2] === "action") {
    await herdr.notify(`操作失败：${error.message}`, "request").catch(() => {});
  }
  process.exitCode = 1;
});

async function main() {
  switch (process.argv[2]) {
    case "startup":
      await resetForStartup();
      return;
    case "action":
      await runAction(localActionId(process.env.HERDR_PLUGIN_ACTION_ID));
      return;
    case "event":
      await runEvent(process.env.HERDR_PLUGIN_EVENT, parseEventData());
      return;
    default:
      throw new Error(`unknown entrypoint: ${process.argv[2] ?? "<missing>"}`);
  }
}

async function resetForStartup() {
  await stateStore.reset();
  await syncAllIndicators(false);
}

async function runAction(actionId) {
  switch (actionId) {
    case "toggle-pane":
      await toggleFocusedPane();
      return;
    case "toggle-all":
      await toggleEveryPane();
      return;
    case "disable-all":
      await stopEverywhere();
      return;
    case "status":
      await showStatus();
      return;
    default:
      throw new Error(`unknown action: ${actionId ?? "<missing>"}`);
  }
}

async function runEvent(eventName, data) {
  const paneId = data?.pane_id;
  if (!paneId) {
    return;
  }

  if (eventName === "pane.agent_detected") {
    await syncPaneIndicator(paneId);
    return;
  }

  if (
    eventName === "pane.agent_status_changed" &&
    data.agent_status === "blocked"
  ) {
    await handleBlockedPane(paneId);
  }
}

async function toggleFocusedPane() {
  const paneId = focusedPaneId();
  const pane = await requireSupportedPane(paneId);
  const enabled = await stateStore.mutate((state) =>
    togglePane(state, pane.terminal_id),
  );

  await herdr.setIndicator(pane.pane_id, normalizeAgent(pane.agent), enabled);
  await herdr.notify(
    `${enabled ? "ON" : "OFF"} · current pane · ${displayAgent(pane.agent)}`,
  );

  if (enabled && pane.agent_status === "blocked") {
    await handleBlockedPane(pane.pane_id);
  }
}

async function toggleEveryPane() {
  const enabled = await stateStore.mutate((state) => toggleGlobal(state));
  const agents = await supportedAgents();

  await Promise.all(
    agents.map((agent) =>
      herdr.setIndicator(agent.pane_id, normalizeAgent(agent.agent), enabled),
    ),
  );
  await herdr.notify(
    `${enabled ? "ON" : "OFF"} · all Codex/Claude panes · ${agents.length} active`,
  );

  if (enabled) {
    for (const agent of agents.filter(
      (item) => item.agent_status === "blocked",
    )) {
      await handleBlockedPane(agent.pane_id);
    }
  }
}

async function stopEverywhere() {
  await stateStore.mutate((state) => disableAll(state));
  const count = await syncAllIndicators(false);
  await herdr.notify(`OFF · emergency stop · ${count} panes cleared`, "request");
}

async function showStatus() {
  const state = await stateStore.readSnapshot();
  const agents = await supportedAgents();
  const enabledCount = agents.filter((agent) =>
    isEnabledForTerminal(state, agent.terminal_id),
  ).length;

  await herdr.notify(
    `global ${state.globalEnabled ? "ON" : "OFF"} · ${enabledCount}/${agents.length} active panes enabled · ${Object.keys(state.paneOverrides).length} overrides`,
  );
}

async function handleBlockedPane(
  paneId,
  {
    retriesRemaining = 1,
    approvalsRemaining = MAX_CHAINED_APPROVALS,
    ignoreFingerprint,
  } = {},
) {
  let ignoredReason;
  let approvedAgent;
  let snapshotChanged = false;

  const initial = await herdr.paneGet(paneId);
  if (
    !initial ||
    !isSupportedAgent(initial.agent) ||
    !initial.terminal_id ||
    (initial.agent_status !== "blocked" && !ignoreFingerprint)
  ) {
    return;
  }

  const initialState = await stateStore.readSnapshot();
  if (
    !isEnabledForTerminal(initialState, initial.terminal_id) ||
    (!ignoreFingerprint &&
      initialState.handledRevisions[initial.terminal_id] === initial.revision)
  ) {
    return;
  }

  const inspection = await waitForApprovalInspection(herdr, paneId, {
    followTransitions: Boolean(ignoreFingerprint),
    ignoreFingerprint,
    maxAttempts: ignoreFingerprint ? FOLLOW_UP_MAX_ATTEMPTS : undefined,
  });
  if (inspection.kind === "aborted") {
    return;
  }

  await stateStore.mutate(async (state) => {
    const current = await herdr.paneGet(paneId);
    if (!isStableBlockedSnapshot(inspection.pane, current)) {
      snapshotChanged = true;
      return;
    }
    if (
      !isEnabledForTerminal(state, current.terminal_id) ||
      state.handledRevisions[current.terminal_id] === current.revision
    ) {
      return;
    }

    state.handledRevisions[current.terminal_id] = current.revision;
    if (inspection.decision.kind !== "approve") {
      ignoredReason = inspection.decision.reason;
      return;
    }

    await herdr.sendKey(current.pane_id, inspection.decision.key);
    approvedAgent = displayAgent(current.agent);
  });

  if (snapshotChanged && retriesRemaining > 0) {
    await handleBlockedPane(paneId, {
      retriesRemaining: retriesRemaining - 1,
      approvalsRemaining,
      ignoreFingerprint,
    });
    return;
  }

  if (approvedAgent) {
    await herdr.notify(`Approved · ${approvedAgent} · ${paneId}`);

    if (approvalsRemaining > 1) {
      await handleBlockedPane(paneId, {
        retriesRemaining: 1,
        approvalsRemaining: approvalsRemaining - 1,
        ignoreFingerprint: inspection.fingerprint,
      });
    }
  } else if (ignoredReason) {
    await herdr.notify(
      `Kept blocked · ${paneId} · ${ignoredReason}`,
      "request",
    );
  }
}

async function syncPaneIndicator(paneId) {
  const pane = await herdr.paneGet(paneId);
  if (!pane || !isSupportedAgent(pane.agent)) {
    return;
  }

  const state = await stateStore.readSnapshot();
  await herdr.setIndicator(
    pane.pane_id,
    normalizeAgent(pane.agent),
    isEnabledForTerminal(state, pane.terminal_id),
  );
}

async function syncAllIndicators(enabled) {
  const agents = await supportedAgents();
  await Promise.all(
    agents.map((agent) =>
      herdr.setIndicator(agent.pane_id, normalizeAgent(agent.agent), enabled),
    ),
  );
  return agents.length;
}

async function supportedAgents() {
  return (await herdr.agentList()).filter(
    (agent) => isSupportedAgent(agent.agent) && agent.terminal_id,
  );
}

async function requireSupportedPane(paneId) {
  const pane = await herdr.paneGet(paneId);
  if (!pane) {
    throw new Error(`pane not found: ${paneId}`);
  }
  if (!isSupportedAgent(pane.agent)) {
    throw new Error("focused pane does not contain Codex or Claude Code");
  }
  if (!pane.terminal_id) {
    throw new Error("focused pane has no terminal identity");
  }
  return pane;
}

function focusedPaneId() {
  if (process.env.HERDR_PANE_ID) {
    return process.env.HERDR_PANE_ID;
  }

  const context = parseJson(process.env.HERDR_PLUGIN_CONTEXT_JSON) ?? {};
  if (!context.focused_pane_id) {
    throw new Error("focused pane context is unavailable");
  }
  return context.focused_pane_id;
}

function parseEventData() {
  const envelope = parseJson(process.env.HERDR_PLUGIN_EVENT_JSON);
  return envelope?.data ?? envelope ?? {};
}

function parseJson(value) {
  if (!value) {
    return undefined;
  }
  try {
    return JSON.parse(value);
  } catch {
    throw new Error("Herdr supplied invalid plugin JSON context");
  }
}

function localActionId(actionId) {
  return actionId?.split(".").at(-1);
}

function displayAgent(agent) {
  return normalizeAgent(agent) === "claude" ? "Claude Code" : "Codex";
}

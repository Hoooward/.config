import { createHash } from "node:crypto";

import {
  classifyApproval,
  isStableBlockedSnapshot,
  isSupportedAgent,
} from "./domain.mjs";

const DEFAULT_INTERVAL_MS = 150;
const DEFAULT_MAX_ATTEMPTS = 12;
const DEFINITIVE_IGNORE_REASONS = new Set([
  "interactive_or_trust_prompt",
  "unsupported_agent",
]);

export async function waitForApprovalInspection(
  herdr,
  paneId,
  {
    wait = delay,
    intervalMs = DEFAULT_INTERVAL_MS,
    maxAttempts = DEFAULT_MAX_ATTEMPTS,
    ignoreFingerprint,
    followTransitions = false,
  } = {},
) {
  let lastInspection;

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const before = await herdr.paneGet(paneId);
    if (!isTrackablePane(before)) {
      return { kind: "aborted", reason: "blocker_disappeared" };
    }

    if (before.agent_status !== "blocked") {
      if (!followTransitions) {
        return { kind: "aborted", reason: "blocker_disappeared" };
      }
      if (attempt + 1 < maxAttempts) {
        await wait(intervalMs);
      }
      continue;
    }

    const screen = await herdr.readDetection(before.pane_id);
    const after = await herdr.paneGet(before.pane_id);
    if (isStableBlockedSnapshot(before, after)) {
      const decision = classifyApproval(before.agent, screen);
      const fingerprint = fingerprintScreen(screen);

      if (
        decision.kind === "approve" &&
        fingerprint === ignoreFingerprint
      ) {
        if (attempt + 1 < maxAttempts) {
          await wait(intervalMs);
        }
        continue;
      }

      lastInspection = {
        kind: decision.kind,
        pane: after,
        decision,
        fingerprint,
      };

      if (
        decision.kind === "approve" ||
        DEFINITIVE_IGNORE_REASONS.has(decision.reason)
      ) {
        return lastInspection;
      }
    }

    if (attempt + 1 < maxAttempts) {
      await wait(intervalMs);
    }
  }

  return (
    lastInspection ?? {
      kind: "aborted",
      reason: "no_stable_snapshot",
    }
  );
}

export function fingerprintScreen(screen) {
  return createHash("sha256").update(String(screen ?? "")).digest("hex");
}

function isTrackablePane(pane) {
  return (
    pane &&
    typeof pane.pane_id === "string" &&
    typeof pane?.terminal_id === "string" &&
    Number.isInteger(pane?.revision) &&
    isSupportedAgent(pane?.agent)
  );
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

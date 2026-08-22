export const SUPPORTED_AGENTS = new Set(["codex", "claude"]);

export function createState(input = {}) {
  return {
    version: 1,
    globalEnabled: input.globalEnabled === true,
    paneOverrides: sanitizeBooleanRecord(input.paneOverrides),
    handledRevisions: sanitizeRevisionRecord(input.handledRevisions),
  };
}

export function normalizeAgent(agent) {
  const normalized = String(agent ?? "").trim().toLowerCase();
  return normalized === "claude-code" ? "claude" : normalized;
}

export function isSupportedAgent(agent) {
  return SUPPORTED_AGENTS.has(normalizeAgent(agent));
}

export function isEnabledForTerminal(state, terminalId) {
  if (Object.hasOwn(state.paneOverrides, terminalId)) {
    return state.paneOverrides[terminalId];
  }

  return state.globalEnabled;
}

export function togglePane(state, terminalId) {
  const next = !isEnabledForTerminal(state, terminalId);
  state.paneOverrides[terminalId] = next;
  delete state.handledRevisions[terminalId];
  return next;
}

export function toggleGlobal(state) {
  state.globalEnabled = !state.globalEnabled;
  state.paneOverrides = {};
  state.handledRevisions = {};
  return state.globalEnabled;
}

export function disableAll(state) {
  state.globalEnabled = false;
  state.paneOverrides = {};
  state.handledRevisions = {};
}

export function isStableBlockedSnapshot(before, after) {
  return (
    before?.pane_id === after?.pane_id &&
    before?.terminal_id === after?.terminal_id &&
    normalizeAgent(before?.agent) === normalizeAgent(after?.agent) &&
    before?.agent_status === "blocked" &&
    after?.agent_status === "blocked" &&
    Number.isInteger(before?.revision) &&
    before.revision === after?.revision
  );
}

export function classifyApproval(agent, screen) {
  const normalizedAgent = normalizeAgent(agent);
  const text = normalizeScreen(screen);

  if (!SUPPORTED_AGENTS.has(normalizedAgent)) {
    return ignore("unsupported_agent");
  }

  if (isExcludedPrompt(text)) {
    return ignore("interactive_or_trust_prompt");
  }

  if (!hasSelectedAffirmativeOption(text)) {
    return ignore("affirmative_option_not_selected");
  }

  if (normalizedAgent === "codex" && isCodexPermissionPrompt(text)) {
    return approve("codex_permission");
  }

  if (normalizedAgent === "claude" && isClaudePermissionPrompt(text)) {
    return approve("claude_permission");
  }

  return ignore("unrecognized_blocker");
}

function sanitizeBooleanRecord(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(value).filter(
      ([key, item]) => key.length > 0 && typeof item === "boolean",
    ),
  );
}

function sanitizeRevisionRecord(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(value).filter(
      ([key, item]) => key.length > 0 && Number.isInteger(item) && item >= 0,
    ),
  );
}

function normalizeScreen(screen) {
  return String(screen ?? "")
    .replace(/\u001B\[[0-?]*[ -/]*[@-~]/g, "")
    .normalize("NFKC")
    .toLowerCase();
}

function isExcludedPrompt(text) {
  return [
    "do you trust the contents of this directory?",
    "enter to submit answer",
    "enter to submit all",
    "review your answers",
    "skip interview and plan immediately",
    "run a dynamic workflow?",
    "askuserquestion",
    "select model",
    "login",
    "sign in",
  ].some((marker) => text.includes(marker));
}

function hasSelectedAffirmativeOption(text) {
  return text.split("\n").some((line) =>
    /^\s*[│┃┆┇╭╰├└┌┐─]*\s*[❯›➜→]\s*(?:\d+[.)]\s*)?(?:yes\b|allow\b|approve\b|proceed\b)/u.test(
      line,
    ),
  );
}

function isCodexPermissionPrompt(text) {
  const flattened = text.replace(/\s+/gu, " ");

  if (text.includes("allow command?")) {
    return true;
  }

  // Codex 的 permission 问句会被窄 terminal 硬换行或裁切；固定前缀已经足够明确，
  // 且外层仍要求 blocked + affirmative selection。
  if (
    /would you like to (?:run|make) the following\b/u.test(flattened)
  ) {
    return true;
  }

  if (/\b(?:requires?|needs?|requesting) (?:your )?(?:approval|permission)\b/u.test(text)) {
    return true;
  }

  const asksForDecision = /\b(?:do you want to|would you like to)\b/u.test(text);
  const namesPermissionTarget =
    /\b(?:run|execute|allow|approve)\b[^\n]{0,80}\b(?:command|tool|network|file edit|write)\b/u.test(
      text,
    ) ||
    /\b(?:command|tool|network|file edit|write)\b[^\n]{0,80}\b(?:run|execute|allow|approve)\b/u.test(
      text,
    );

  return asksForDecision && namesPermissionTarget;
}

function isClaudePermissionPrompt(text) {
  if (
    text.includes("waiting for permission") ||
    text.includes("do you want to allow this connection?")
  ) {
    return true;
  }

  if (!text.includes("do you want to proceed?")) {
    return false;
  }

  return /\b(?:bash command|bash\(|tool use|permission|mcp|connection|edit\(|write\(|read\()\b/u.test(
    text,
  );
}

function approve(reason) {
  return { kind: "approve", key: "enter", reason };
}

function ignore(reason) {
  return { kind: "ignore", reason };
}

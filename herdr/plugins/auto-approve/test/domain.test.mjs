import assert from "node:assert/strict";
import test from "node:test";

import {
  classifyApproval,
  createState,
  disableAll,
  isEnabledForTerminal,
  isStableBlockedSnapshot,
  toggleGlobal,
  togglePane,
} from "../src/domain.mjs";

test("pane override reverses the effective global policy", () => {
  const state = createState();

  assert.equal(togglePane(state, "term-1"), true);
  assert.equal(isEnabledForTerminal(state, "term-1"), true);
  assert.equal(isEnabledForTerminal(state, "term-2"), false);

  assert.equal(toggleGlobal(state), true);
  assert.deepEqual(state.paneOverrides, {});
  assert.equal(isEnabledForTerminal(state, "term-1"), true);

  assert.equal(togglePane(state, "term-1"), false);
  assert.equal(isEnabledForTerminal(state, "term-1"), false);
  assert.equal(isEnabledForTerminal(state, "term-2"), true);
});

test("emergency stop clears every policy and handled revision", () => {
  const state = createState({
    globalEnabled: true,
    paneOverrides: { "term-1": false },
    handledRevisions: { "term-1": 42 },
  });

  disableAll(state);

  assert.equal(state.globalEnabled, false);
  assert.deepEqual(state.paneOverrides, {});
  assert.deepEqual(state.handledRevisions, {});
});

test("Codex command permission with selected Yes is approved", () => {
  const decision = classifyApproval(
    "codex",
    `Allow command?\n\n› 1. Yes, proceed\n  2. No, and tell Codex what to do differently\n\npress enter to confirm or esc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "approve",
    key: "enter",
    reason: "codex_permission",
  });
});

test("Codex permission remains recognizable when the terminal splits command across rows", () => {
  const decision = classifyApproval(
    "codex",
    `Would you like to run the following com
mand?

› 1. Yes, proceed (y)
  2. No, and tell Codex what to do differently

Press enter to confirm or esc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "approve",
    key: "enter",
    reason: "codex_permission",
  });
});

test("Codex file edit permission is approved even when its label is clipped", () => {
  const decision = classifyApproval(
    "codex",
    `Would you like to make the following ed

› 1. Yes, proceed (y)
  2. No, and tell Codex what to do differently

Press enter to confirm or esc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "approve",
    key: "enter",
    reason: "codex_permission",
  });
});

test("Codex question and directory trust prompts stay blocked", () => {
  assert.equal(
    classifyApproval(
      "codex",
      `What should the API return?\n❯ 1. Yes\nenter to submit answer`,
    ).kind,
    "ignore",
  );
  assert.equal(
    classifyApproval(
      "codex",
      `Do you trust the contents of this directory?\n❯ Yes, continue`,
    ).kind,
    "ignore",
  );
});

test("Claude Bash permission with selected Yes is approved", () => {
  const decision = classifyApproval(
    "claude-code",
    `Bash command\nrm -i generated.tmp\nDo you want to proceed?\n❯ 1. Yes\n  2. Yes, and don't ask again\n  3. No\nEsc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "approve",
    key: "enter",
    reason: "claude_permission",
  });
});

test("Claude permission stays blocked when No is selected", () => {
  const decision = classifyApproval(
    "claude",
    `Bash command\nDo you want to proceed?\n  1. Yes\n❯ 2. No\nEsc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "ignore",
    reason: "affirmative_option_not_selected",
  });
});

test("unknown blockers stay blocked even with an affirmative option", () => {
  const decision = classifyApproval(
    "claude",
    `Choose the release strategy\n❯ Yes, use canary\nEsc to cancel`,
  );

  assert.deepEqual(decision, {
    kind: "ignore",
    reason: "unrecognized_blocker",
  });
});

test("revision guard requires an unchanged blocked pane", () => {
  const before = {
    pane_id: "w1:p1",
    terminal_id: "term-1",
    agent: "codex",
    agent_status: "blocked",
    revision: 42,
  };

  assert.equal(isStableBlockedSnapshot(before, { ...before }), true);
  assert.equal(
    isStableBlockedSnapshot(before, { ...before, revision: 43 }),
    false,
  );
  assert.equal(
    isStableBlockedSnapshot(before, { ...before, agent_status: "idle" }),
    false,
  );
});

import assert from "node:assert/strict";
import test from "node:test";

import { waitForApprovalInspection } from "../src/inspect.mjs";

test("keeps inspecting while a blocked permission UI is still rendering", async () => {
  const panes = [pane(10), pane(10), pane(11), pane(11)];
  const screens = [
    "Action Required",
    `Would you like to run the following com
mand?
› 1. Yes, proceed (y)
Press enter to confirm or esc to cancel`,
  ];
  const herdr = {
    async paneGet() {
      return panes.shift();
    },
    async readDetection() {
      return screens.shift();
    },
  };

  const result = await waitForApprovalInspection(herdr, "w1:p1", {
    wait: async () => {},
  });

  assert.equal(result.kind, "approve");
  assert.equal(result.pane.revision, 11);
  assert.equal(panes.length, 0);
  assert.equal(screens.length, 0);
});

test("skips an approved prompt fingerprint and waits for the next permission", async () => {
  const runPermission = `Would you like to run the following command?
› 1. Yes, proceed (y)
Press enter to confirm or esc to cancel`;
  const editPermission = `Would you like to make the following edits?
› 1. Yes, proceed (y)
Press enter to confirm or esc to cancel`;

  const first = await waitForApprovalInspection(
    fakeHerdr([pane(20), pane(20)], [runPermission]),
    "w1:p1",
    { wait: async () => {} },
  );
  const second = await waitForApprovalInspection(
    fakeHerdr(
      [pane(21), pane(21), pane(22), pane(22)],
      [runPermission, editPermission],
    ),
    "w1:p1",
    { wait: async () => {}, ignoreFingerprint: first.fingerprint },
  );

  assert.equal(first.kind, "approve");
  assert.equal(second.kind, "approve");
  assert.equal(second.pane.revision, 22);
  assert.notEqual(second.fingerprint, first.fingerprint);
});

test("follows an agent transition until the next permission appears", async () => {
  const editPermission = `Would you like to make the following edits?
› 1. Yes, proceed (y)
Press enter to confirm or esc to cancel`;
  const panes = [
    pane(30, "working"),
    pane(31, "idle"),
    pane(32),
    pane(32),
  ];
  const herdr = fakeHerdr(panes, [editPermission]);

  const result = await waitForApprovalInspection(herdr, "w1:p1", {
    followTransitions: true,
    maxAttempts: 4,
    wait: async () => {},
  });

  assert.equal(result.kind, "approve");
  assert.equal(result.pane.revision, 32);
  assert.equal(panes.length, 0);
});

function pane(revision, agentStatus = "blocked") {
  return {
    pane_id: "w1:p1",
    terminal_id: "term-1",
    agent: "codex",
    agent_status: agentStatus,
    revision,
  };
}

function fakeHerdr(panes, screens) {
  return {
    async paneGet() {
      return panes.shift();
    },
    async readDetection() {
      return screens.shift();
    },
  };
}

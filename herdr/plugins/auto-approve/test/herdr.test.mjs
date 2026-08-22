import assert from "node:assert/strict";
import test from "node:test";

import { Herdr } from "../src/herdr.mjs";

test("mutation commands accept Herdr's empty successful response", async () => {
  const calls = [];
  const herdr = new Herdr("herdr-test", async (binary, args) => {
    calls.push({ binary, args });
    return { stdout: "", stderr: "" };
  });

  await herdr.sendKey("w1:p1", "enter");
  await herdr.setIndicator("w1:p1", "codex", false);

  assert.deepEqual(calls, [
    {
      binary: "herdr-test",
      args: ["agent", "send-keys", "w1:p1", "enter"],
    },
    {
      binary: "herdr-test",
      args: [
        "pane",
        "report-metadata",
        "w1:p1",
        "--source",
        "plugin:auto-approve",
        "--agent",
        "codex",
        "--clear-token",
        "auto_approve",
      ],
    },
  ]);
});

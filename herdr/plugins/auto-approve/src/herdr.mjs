import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const COMMAND_TIMEOUT_MS = 5_000;

export class Herdr {
  constructor(
    binary = process.env.HERDR_BIN_PATH ?? "herdr",
    run = execFileAsync,
  ) {
    this.binary = binary;
    this.run = run;
  }

  async paneGet(paneId) {
    const response = await this.json(["pane", "get", paneId]);
    return response.result?.pane;
  }

  async agentList() {
    const response = await this.json(["agent", "list"]);
    return response.result?.agents ?? [];
  }

  async readDetection(paneId) {
    return this.text(["agent", "read", paneId, "--source", "detection"]);
  }

  async sendKey(paneId, key) {
    await this.text(["agent", "send-keys", paneId, key]);
  }

  async setIndicator(paneId, agent, enabled) {
    const args = [
      "pane",
      "report-metadata",
      paneId,
      "--source",
      "plugin:auto-approve",
      "--agent",
      agent,
    ];

    if (enabled) {
      args.push("--token", "auto_approve=AUTO");
    } else {
      args.push("--clear-token", "auto_approve");
    }

    await this.text(args);
  }

  async notify(body, sound = "none") {
    await this.json([
      "notification",
      "show",
      "Auto-approve",
      "--body",
      body,
      "--sound",
      sound,
    ]);
  }

  async json(args) {
    const output = await this.text(args);
    const parsed = JSON.parse(output);
    if (parsed.error) {
      throw new Error(parsed.error.message ?? "Herdr command failed");
    }
    return parsed;
  }

  async text(args) {
    const { stdout } = await this.run(this.binary, args, {
      encoding: "utf8",
      maxBuffer: 1024 * 1024,
      timeout: COMMAND_TIMEOUT_MS,
      windowsHide: true,
    });
    return stdout;
  }
}

import { open, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";

import { createState } from "./domain.mjs";

const LOCK_RETRY_MS = 20;
const LOCK_TIMEOUT_MS = 2_000;
const STALE_LOCK_MS = 10_000;

export class StateStore {
  constructor(directory) {
    if (!directory) {
      throw new Error("HERDR_PLUGIN_STATE_DIR is required");
    }

    this.statePath = path.join(directory, "runtime.json");
    this.lockPath = path.join(directory, "runtime.lock");
  }

  async reset() {
    await this.withLock(async () => {
      await this.write(createState());
    });
  }

  async readSnapshot() {
    return createState(await this.readRaw());
  }

  async mutate(callback) {
    return this.withLock(async () => {
      const state = createState(await this.readRaw());
      const result = await callback(state);
      await this.write(state);
      return result;
    });
  }

  async readRaw() {
    try {
      return JSON.parse(await readFile(this.statePath, "utf8"));
    } catch (error) {
      if (error?.code === "ENOENT" || error instanceof SyntaxError) {
        return {};
      }
      throw error;
    }
  }

  async write(state) {
    const temporaryPath = `${this.statePath}.${process.pid}.tmp`;
    await writeFile(temporaryPath, `${JSON.stringify(state, null, 2)}\n`, {
      encoding: "utf8",
      mode: 0o600,
    });
    await rename(temporaryPath, this.statePath);
  }

  async withLock(callback) {
    const startedAt = Date.now();

    while (true) {
      try {
        const handle = await open(this.lockPath, "wx", 0o600);
        try {
          return await callback();
        } finally {
          await handle.close();
          await rm(this.lockPath, { force: true });
        }
      } catch (error) {
        if (error?.code !== "EEXIST") {
          throw error;
        }

        await this.removeStaleLock();
        if (Date.now() - startedAt >= LOCK_TIMEOUT_MS) {
          throw new Error("timed out waiting for auto-approve state lock");
        }
        await delay(LOCK_RETRY_MS);
      }
    }
  }

  async removeStaleLock() {
    try {
      const info = await stat(this.lockPath);
      if (Date.now() - info.mtimeMs > STALE_LOCK_MS) {
        await rm(this.lockPath, { force: true });
      }
    } catch (error) {
      if (error?.code !== "ENOENT") {
        throw error;
      }
    }
  }
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

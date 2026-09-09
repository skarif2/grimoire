#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";

const PLUGIN = "claude-kit/.claude-plugin/plugin.json";
const FILES = [PLUGIN, "README.md"];

const now = new Date();
const stamp = `${String(now.getFullYear()).slice(2)}.${now.getMonth() + 1}${String(now.getDate()).padStart(2, "0")}`;

const old = JSON.parse(readFileSync(PLUGIN, "utf8")).version;
const [oldStamp, oldCount] = [old.split(".").slice(0, 2).join("."), Number(old.split(".")[2] ?? 0)];
const next = oldStamp === stamp ? `${stamp}.${oldCount + 1}` : `${stamp}.0`;

if (old === next) {
  console.log(`already ${old}, nothing to do`);
  process.exit(0);
}

for (const f of FILES) {
  const before = readFileSync(f, "utf8");
  const after = before.split(old).join(next);
  if (before === after) {
    console.error(`${f} does not mention ${old}`);
    process.exit(1);
  }
  writeFileSync(f, after);
}

const stragglers = execSync(
  `git grep -ln --fixed-strings '${old}' -- . ':!scripts' || true`,
  { encoding: "utf8" },
).trim();

console.log(`${old} -> ${next}`);
console.log(FILES.map((f) => `  ${f}`).join("\n"));
if (stragglers) console.error(`\nstill on ${old}:\n${stragglers}`);

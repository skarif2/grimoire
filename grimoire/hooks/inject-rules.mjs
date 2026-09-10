#!/usr/bin/env node
// Emits rules/*.md as additionalContext. A plugin cannot write a user's CLAUDE.md,
// so this is the only channel for content that must be resident every turn.
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const LIMIT = 10000; // Claude Code truncates hook output beyond this

try {
  const dir = join(process.env.CLAUDE_PLUGIN_ROOT ?? ".", "rules");
  const body = readdirSync(dir)
    .filter((f) => f.endsWith(".md"))
    .sort()
    .map((f) => readFileSync(join(dir, f), "utf8").trim())
    .join("\n\n");

  if (!body) process.exit(0);
  if (body.length > LIMIT) {
    process.stderr.write(`grimoire: rules are ${body.length} chars, over the ${LIMIT} hook limit\n`);
    process.exit(0);
  }

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: body },
  }));
} catch {
  process.exit(0); // never block a session start
}

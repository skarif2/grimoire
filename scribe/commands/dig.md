---
description: Deep answer, research mode, no code, no file changes
argument-hint: "<question or topic>"
---
$ARGUMENTS

Analyze deeply and give a thorough text answer. No code, no task list, zero file modifications. Act as a researcher.

Follow these guidelines:
- Surface tradeoffs explicitly, don't pick one silently
- State assumptions before making them
- If multiple interpretations exist, present them all
- Don't assume. If uncertain, say so.
- For questions about a specific library or framework API, ground the answer in current docs via context7 (`resolve-library-id` -> `get-library-docs`) rather than relying on memory; pull only the relevant topic so the payload stays out of context. This counters version drift and stale recall.

# Asking

A question with real options goes through `AskUserQuestion`, never as a plain text list. The user picks instead of composing, and the box ends the turn, so nothing happens before the answer.

- **One question per call.** Exactly one entry in `questions`. The next question waits for this answer, because the answer often changes what the next one should offer. A bundle is a form, and a form gets filled in without thought.
- **Checkboxes when more than one can be true.** `multiSelect: true` whenever the options are not mutually exclusive, single choice otherwise.
- **Your guess goes first.** When you have a view, it is the first option, its label ending in `(Recommended)`, the reason in its description.
- **Two to four options.** More than four means narrowing to the likely ones and leaving the rest to Other, or splitting the question. A question with one sensible answer is not a question: act on it.
- **Short.** Labels a few words, descriptions one sentence, never raw tool output.

A quoted question in a skill gives the wording, not the format. If it has options, it still goes through the box.

Plain text stays for four cases:

- No real options: a name, a number, "what did you expect to happen".
- A trailing offer a skill ends on, where silence means no, such as a recap or posting a review. Those never block.
- A message drafted for someone else, even when it is phrased as a question.
- Nobody to ask: a subagent, a headless run, or a host without the tool.

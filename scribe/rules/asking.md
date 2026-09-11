# Asking

A question with real options goes through `AskUserQuestion`, never as a plain text list. The user picks instead of composing, and the box ends the turn, so nothing happens before the answer.

- **One question per call.** One entry in `questions`. The next question waits, because the answer often changes what it should offer. A bundle is a form, and a form gets filled in without thought.
- **Checkboxes when more than one can be true.** `multiSelect: true` whenever the options are not mutually exclusive, single choice otherwise.
- **Your guess goes first.** When you have a view, it is the first option, its label ending in `(Recommended)`, the reason in its description.
- **Two to four options.** More than four: narrow to the likely ones and leave the rest to Other, or split the question. One sensible answer is not a question: act on it.
- **Short.** Labels a few words, descriptions one sentence, never raw tool output.

A quoted question in a skill gives the wording, not the format. If it has options, it still goes through the box.

Plain text stays for five cases:

- No real options: a name, a number, "what did you expect to happen".
- A yes or no before one action: load this handoff, delete it, overwrite the plan. Two answers is not a list.
- A trailing offer a skill ends on, where silence means no: a recap, posting a review. Those never block.
- A message drafted for someone else, even when it is phrased as a question.
- Nobody to ask: a subagent, a headless run, or a host without the tool.

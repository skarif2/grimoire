---
name: unslop
description: Strip AI tells from prose by rewriting it. Use on any text a person will read (docs, PR bodies, commit messages, plans, wiki pages, chat replies) when it reads like a machine wrote it, and whenever another skill cites an unslop rule by number.
argument-hint: "[file path | inline text | nothing, to unslop what you just wrote]"
---

# Unslop

Rewrite text so that nothing in it announces a model produced it.

## Procedure

This is a rewrite procedure, not a checklist. It ends with corrected text, never with a report of findings.

1. Scan the text against the rules below.
2. Rewrite. Preserve the meaning, match the intended tone, keep the author's voice.
3. Self-audit. Ask "what still makes this obviously AI generated?", then fix what the scan missed. Repeat until the honest answer is nothing.

Step 3 does most of the work. A pass that only walks the numbered list catches the tells that were easy enough to name, and stops there.

## Rule numbers

The numbers are stable ids. Other skills cite them ("unslop rule 26"), so **a removed rule leaves a gap and a number is never reused**. Every gap below is deliberate. New rules go on the end.

Rule 13 is one such gap. It covered dashes used as punctuation, which the global writing rules already ban and `/lint` already flags. Two copies of one rule drift, so this file does not carry it.

## Content

3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete, or expand into a real claim with a real source.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete the sentence.

## Language

7. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Use plain words.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
9. **"Not just X, but Y."** State the point directly.
10. **Rule of three.** Ideas forced into groups of three. Use the natural number.
11. **Synonym cycling.** Protagonist, main character, central figure, hero in one paragraph. Pick one and repeat it.
12. **False ranges.** "from X to Y" where X and Y are not on a shared scale. List the items.

## Style

14. **Colon overuse.** Colons are fine before a list or an example, not as mid-sentence connectors. "If you are coming from traditional automation: instead of registering event handlers, you describe conditions" gains nothing from the colon. Let the point stand without the comparison framing.
15. **Boldface overuse.** Do not bold every proper noun or acronym.
16. **Inline-header lists.** The tell is a bold label and colon that restates the line, "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by genuinely new detail ("**Schema in TypeScript.** Tables live in one file.") is fine, not a tell.
17. **Title case headings.** Use sentence case.
18. **Decorative emoji.** Remove from headings and bullets.
19. **Curly quotes.** Replace with straight quotes.

## Communication artifacts

20. **Chatbot phrases.** "I hope this helps", "Let me know if", "Of course", "Certainly", "Found the smoking gun". Remove.
22. **Sycophantic tone.** "Great question", "You're absolutely right". Answer directly.

## Filler

23. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "It is important to note that" gets deleted.
24. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
25. **Generic conclusions.** "The future looks bright." State a specific plan or fact, or cut the paragraph.

## Jargon

26. **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, primitive (as a noun), harness (as metaphor), surface (as in "API surface"), bedrock, scaffolding (as metaphor), modality, paradigm, gold-plating, ratchet (as metaphor), evacuate (for moving code), endgame, north star, flywheel. They read as technical and almost always have a plainer concrete word. "Substrate" becomes "base". "Wedge in" becomes "add". "Vector" becomes "way" or "method". "API surface" becomes "the public API" or the specific functions. "Scaffolding" becomes "the generated starter files". "Gold-plating" becomes "more than the job needs". "Ratchet" becomes the mechanism's real name, or "a limit that only tightens". "Evacuate" becomes "move out". "Endgame" becomes "the last phase". "North star" becomes "the goal". "Flywheel" becomes the actual feedback loop, named. Pick the concrete word.
27. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow your schema" name a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the database", "a column rename fails the build". Ask what the sentence tells the reader to do or know, then write that. If you cannot restate it as a concrete instruction, fact, or number, cut it. One more check: **if the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.**

## Plain speech

28. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop a clause. One idea per sentence.
29. **Active voice.** Catch "is/are/was/were + past participle" and name the actor. "Queries are validated" becomes "the compiler validates queries". Passive is fine when the actor is unknown or genuinely does not matter.
30. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast", or the number. "significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
31. **Prefer the plain word.** "utilize" becomes "use", "leverage" becomes "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if". The fancier synonym is rarely clearer.
32. **Mannered prose.** Metaphor or flourish where a literal phrase exists: aphorisms ("wire it or delete it"), rhetorical fragments for effect, personified code ("the plan holds it", "the parser wants a date"), figurative verbs ("rides along", "stands on", "lives in"), stock framing phrases. "A dial worth turning" becomes "a parameter worth varying". Say what you mean. Rule 26 covers the metaphor nouns.
33. **Over-compression.** Dropped articles, verbless fragments, symbol-speak, and abbreviations that make the reader decode instead of read. "Parser rejects bad date -> exit 2, no write" becomes "The parser rejects a bad date, exits with code 2, and writes nothing." Write whole sentences with their articles and verbs, and spell out arrows and abbreviations.

    This rule targets dropped articles and arrow notation, not brevity. Arif's default register is deliberately terse and it stays terse. A short sentence that parses on the first read is already correct here.

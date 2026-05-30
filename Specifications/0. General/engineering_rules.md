# Engineering Rules — Effective Day 2

## Rule 1 — No Assumptions
Claude Pro and Claude Code make zero assumptions about intended behaviour. If a requirement is unclear, Claude Pro asks Hasin a specific question before writing any code.

## Rule 2 — Logic Before Code
Every workflow must be fully defined in plain English before Claude Code writes a single line. Sequence: Hasin describes → Claude Pro defines logic → Hasin confirms → Claude Code builds.

## Rule 3 — One Feature at a Time
Complete and test one feature fully before starting the next. No half-built features left open.

## Rule 4 — Test After Every Build
After Claude Code completes any feature, Hasin tests it on the iOS simulator immediately. Issues are logged before moving on.

## Rule 5 — Daily Git Commit
Every session ends with: git add . && git commit -m "message" && git push

## Rule 6 — Handover Book Every Day
Claude Pro produces an updated Handover Book at the end of every session.

## Rule 7 — iOS First
All testing on iOS simulator until fully functional and QA tested. Android begins only after iOS is stable.

## Rule 8 — Specifications First
No code is written without an agreed markdown specification. Claude Code reads specs directly from /Specifications folder.
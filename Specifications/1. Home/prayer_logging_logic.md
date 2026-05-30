# Prayer Logging Logic

## Prayer Windows
| Prayer | Window Opens | Window Closes |
|---|---|---|
| Fajr | Fajr time | Dhuhr time |
| Dhuhr | Dhuhr time | Asr time |
| Asr | Asr time | Maghrib time |
| Maghrib | Maghrib time | Isha time |
| Isha | Isha time | Next day Fajr |

## Core User Behaviour
- Tick within window → circle turns green immediately
- Untick within window → circle returns to default empty state
- Window closes without tick → grey empty circle, permanent, non-interactive
- Previous day history: read-only, 7 days rolling

## Premium User Behaviour
- Can tick any prayer until midnight of same calendar day
- Can retroactively tick previous days (cosmetic only — no streak credit)
- Previous day history: read/write cosmetic, 30 days rolling

## Untick Consequence
- Unticking 5th green tick → streak day voided immediately
- Multiplier earned from that day removed immediately
- Re-ticking within open window → all rewards fully restored

## History Navigation
- < and > arrows beside date on Home screen
- Today = default view
- Core: 7 days back (read-only)
- Premium: 30 days back (cosmetic tick available)
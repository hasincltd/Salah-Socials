# Mosque Tap Workflow

## Pin States
| State | Colour |
|---|---|
| Default | Grey/muted |
| Tapped | Gold |
| Favourited | Green (persists until unfavourited) |
| Favourited + Tapped | Green supersedes gold |

- Tapping a new mosque deselects previously tapped mosque (returns to default or green if favourited)

## Bottom Sheet on Tap
- Mosque name (large)
- Distance in teal (e.g. "0.3 miles away")
- Address
- Mosque icon top right
- Prayer times from Aladhan API for mosque GPS coordinates — live
- Active prayer slot highlighted in green
- Get Directions button (gold, full width) → opens Apple Maps / Google Maps / Waze
- Favourite star → toggles green, saved to local storage (Firebase Phase 2)
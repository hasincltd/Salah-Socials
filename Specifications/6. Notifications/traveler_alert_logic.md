# Traveler Alert Logic

## Trigger Conditions
- User detected outside home area (beyond 2 miles of home location)
- Prayer time within 30 minutes

## Notification Format
- "It's almost [Prayer] time — [Mosque Name] is [X] miles away. Want directions? 🕌"
- Tapping notification → opens Mosque tab with that mosque pre-selected in bottom sheet

## Behaviour
- Shows closest mosque to current location
- If multiple mosques equidistant, shows the one with soonest prayer time
- Can be toggled on/off in Settings
# Prayer Notification Logic

## Prayer Time Notification (all users)
- Fires at start of each prayer window
- Message: "It's [Prayer] time — [X] friends are praying now 🕌"

## 15 Minute Warning
- Fires 15 minutes before prayer window closes if prayer not yet ticked
- Message: "[Most interacted friend] and [X] others have prayed [Prayer] — you have 15 minutes, quick!"
- Friend name = user's most interacted friend on leaderboard
- If no friends have prayed yet: "You have 15 minutes left to pray [Prayer] ⏳"

## Post-Prayer Social Nudge
- Fires when a friend completes a prayer
- Message: "[Friend] just prayed [Prayer] — join them before the window closes 🤲"

## Fajr Special Notification
- Highest priority — separate gentle notification at Fajr time
- Message: "The best prayer is Fajr — [Friend] just prayed theirs 🌙"
- Overrides Do Not Disturb with gentle sound only

## Notification Settings
- Each prayer notification toggleable in Settings
- Timing adjustable: at prayer time / 15 min before / 30 min before
- DND hours settable — Fajr overrides DND
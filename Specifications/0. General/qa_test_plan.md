# QA Test Plan

## Testing Approach
- Test on iOS Simulator (iPhone 17, iOS 26.5) for all MVP features
- One feature tested completely before next feature begins
- Edge cases defined before each feature is built

## Edge Cases to Test Per Feature

### Prayer Times
- [ ] Location permission denied — graceful fallback to manual input
- [ ] No internet connection — cached times shown with offline indicator
- [ ] Crossing midnight — Isha window correctly transitions to next day Fajr
- [ ] Travelling to different timezone — times update correctly

### Prayer Logging
- [ ] Tapping tick at exact moment window closes
- [ ] Unticking 5th prayer removes streak day
- [ ] Re-ticking within window restores streak day and multiplier
- [ ] Grey circle cannot be tapped after window closes
- [ ] Premium user tick until midnight works correctly
- [ ] Previous day navigation shows correct states

### Streak Logic
- [ ] Missing one prayer resets Active Streak Count to 0
- [ ] 2x multiplier triggers at exactly day 7
- [ ] Multiplier calculation correct: day 8 = 9, day 10 = 13
- [ ] Total Streak Score never resets
- [ ] Revive popup appears on every app open within 24 hours
- [ ] Revive popup disappears after 24 hours
- [ ] Core user revive deducts 50 coins correctly
- [ ] Premium user gets 4 revives per calendar month

### SS Coins
- [ ] Coin balance equals Total Streak Score on fresh account
- [ ] Spending coins reduces balance but not Total Streak Score
- [ ] New streak units add to both balance and Total Streak Score
- [ ] Balance updates in real time after purchase

### Mosque Finder
- [ ] Map loads correctly with dark theme
- [ ] Mosque pins appear within selected radius
- [ ] Search this area fires when map dragged beyond 10 miles
- [ ] No mosques found shows correct popup
- [ ] Tapping mosque highlights gold, previous deselects
- [ ] Favouriting mosque turns green and persists
- [ ] Favourited + tapped shows green (green supersedes gold)
- [ ] Get Directions opens correct maps app
- [ ] Prayer times update live for selected mosque

### Events Tab (MVP — Locked)
- [ ] Screen shows at 25% opacity
- [ ] Lock icon visible in centre
- [ ] Coming Soon message visible
- [ ] Scrolling works
- [ ] No tapping or interaction beyond scrolling

### Community
- [ ] Active leaderboard shows friends only with Active Streak Count
- [ ] All Time leaderboard shows friends only with Total Streak Score
- [ ] My Mosque shows friends + mosque-registered users
- [ ] Top 100 shows country-based top 100 by Active Streak Count
- [ ] Non-friend profile shows username and avatar only
- [ ] Friend Request button turns gold and shows sent when tapped

### Notifications (Bell Icon)
- [ ] Friend requests appear at top
- [ ] 15 minute prayer warning fires correctly
- [ ] Post-prayer social nudge fires when friend prays
- [ ] Streak lost notification fires immediately
- [ ] Revive reminder fires on app open within 24 hours
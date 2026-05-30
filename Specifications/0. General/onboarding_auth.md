# Onboarding and Authentication Specification

## Authentication Methods
- Email and password (Firebase Auth)
- Sign in with Apple (required for iOS App Store)
- Sign in with Google
- Persistent session via Firebase — stays logged in
- Biometric login (Face ID / Touch ID) optional, set in Settings
- Session expires after 30 days inactivity

## Onboarding Flow — 7 Screens

### Screen 1 — Welcome
- Salah Socials logo, Arabic subtitle, tagline
- "Get Started" button (primary gold)
- "I already have an account" button (secondary)

### Screen 2 — Sign Up / Sign In
- Email/password fields
- Apple SSO button
- Google SSO button
- Password: min 8 characters, 1 number
- "Forgot password" link → email reset via Firebase

### Screen 3 — Your Profile
- Username input — unique, checked against Firebase in real time
- Display name input
- Optional profile picture upload
- Note: "You can update this anytime"

### Screen 4 — Your Location
- Location permission request
- Explanation: "We use your location for accurate prayer times and nearby mosques"
- Allow button → uses device GPS
- Set Manually → postcode input → pin-drop map popup → confirm
- Location saved as Home in Settings

### Screen 5 — Your Mosque (Optional)
- "Set your home mosque" — searchable via Google Places API
- Selected mosque shows prayer times preview
- Skip button clearly visible

### Screen 6 — Notifications
- Notification permission request
- Preview of notification types shown
- Allow / Not Now options
- "Not Now" note: "Enable in Settings anytime"

### Screen 7 — Find Friends
- Search by username
- Import from contacts (optional, permission required)
- QR code share option
- Skip option clearly visible

### Completion
- Lands on Home screen
- Brief animated welcome overlay: "Welcome to Salah Socials, [Name] 🌙"
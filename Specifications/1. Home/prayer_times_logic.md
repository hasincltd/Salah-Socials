# Prayer Times Logic

## Data Source
- Aladhan API (free, no key required)
- Endpoint: api.aladhan.com/v1/timings/{timestamp}
- Calculation method: Muslim World League (Sunni standard)

## Location
- Default: device GPS location
- Manual override: postcode input → pin-drop map popup → saved as Home in Settings
- Times recalculate immediately on location change
- Refresh every second for live accuracy

## Mosque Times
- Sourced from Aladhan API using mosque GPS coordinates
- No manual mosque input required
- Kept up to date automatically
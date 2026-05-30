# Mosque Finder Logic

## Location Controls
- Top of map: "Current Location" pill and "Choose Address" dropdown
- Choose Address: postcode or address input → map reanchors to that location
- Current Location pin always centred by default
- Manual address anchor also centres on chosen address

## Radius Filter
- Pills: 0.5mi / 1mi / 5mi / 10mi
- Changing radius recentres on current/chosen location — never jumps to nearest mosque
- Zoom Out also recentres on current location

## Search This Area
- Fires when user drags map beyond 10 mile range from anchor point
- Banner appears at top of map: "Search this area"
- Tapping refreshes mosque results for current map view
- No mosques found → popup: "No Mosques Found in This Area"

## Data Source
- Google Places API — live queries, no pre-loaded database
- Global coverage via Places API
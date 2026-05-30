# Directions Workflow

## Behaviour
- "Get Directions" button tapped → action sheet appears with options:
  - Apple Maps
  - Google Maps (if installed)
  - Waze (if installed)
- Deep link format:
  - Apple Maps: maps://maps.apple.com/?daddr={lat},{lng}
  - Google Maps: comgooglemaps://?daddr={lat},{lng}&directionsmode=walking
  - Waze: waze://?ll={lat},{lng}&navigate=yes
- If Google Maps/Waze not installed, option is greyed out
- Apple Maps always available as fallback
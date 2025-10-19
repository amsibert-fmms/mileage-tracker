# Mileage Tracker MVP Checklist

## Core Trip Logging
- [ ] Start trip button captures timestamp and starting GPS coordinates.
- [ ] Stop trip button captures timestamp and ending GPS coordinates.
- [ ] Trip duration is calculated from start/stop timestamps.
- [ ] Distance is estimated between start and end coordinates.
- [ ] Average speed is derived from distance and duration.

## Vehicle & Metadata Inputs
- [ ] Active vehicle can be selected at trip start.
- [ ] Vehicle list stores make, model, plate, and notes.
- [ ] Optional odometer adjustment slider allows manual override.
- [x] Trip can be tagged as Business, Personal, Commute, or Other.
- [ ] Last used vehicle and tag selections surface automatically to minimise taps.

## Location Handling
- [ ] GPS requests fire only during active trip sessions.
- [ ] Reverse geocoding resolves start/end locations for display.
- [ ] Location reads queue when offline and retry when service resumes.
- [ ] Raw coordinate snapshots persist with trips for export verification.

## Data Storage & Export
- [ ] Trips persist locally via SQLite with structured schema.
- [ ] Data export produces CSV compatible with Google Sheets.
- [ ] Local data saved prior to any optional sync attempts.
- [ ] Google Sheets sync mirrors the SQLite dataset into a private spreadsheet.
- [ ] Automated or scheduled backups are documented for both CSV and Sheets workflows.

## Nice-to-Have (Deferred from MVP)
- Auto trip detection via motion/Bluetooth triggers.
- Cloud synchronization (Google Sheets or similar).
- Map-based route visualization.
- Analytics dashboard beyond per-trip summary.
- Voice notes or shortcuts for hands-free trip annotation.


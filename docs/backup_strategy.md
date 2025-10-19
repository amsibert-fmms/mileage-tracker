# Backup strategy

With GPS-backed logging and SQLite persistence in place, the mileage tracker now
supports multiple local and cloud-friendly export paths.

## Local backups
- Trips and vehicles are stored in the on-device SQLite database located under
  the application documents directory (`mileage_tracker.db`).
- A CSV export can be triggered from the overflow menu on the home screen. The
  export writes to `mileage-trips.csv` in the same documents directory so it can
  be copied to external storage or emailed.
- Each export is generated from the latest repository state only after all
  queued writes have been flushed, ensuring the CSV reflects committed trips.

## Google Sheets mirroring
- The home screen also exposes a "Mirror to Google Sheets" action. In
  development builds this uses `FileMirroringSheetsClient` to persist the payload
  alongside the database, while the production client can be swapped out for a
  real Sheets integration using OAuth.
- The trip payload mirrors the SQLite schema including raw GPS samples so the
  sheet can be used as an off-device backup or for lightweight analytics.

## Recommendations
- Schedule regular CSV exports (weekly or monthly depending on mileage volume)
  and store them in a versioned cloud folder.
- Pair CSV exports with a Sheets sync so trip summaries are visible even if the
  device is lost.
- When rolling out the live Sheets client, ensure the OAuth credentials are kept
  outside of source control and that failed syncs are retried using the existing
  persistence queue.

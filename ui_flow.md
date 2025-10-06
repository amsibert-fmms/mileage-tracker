# UI Flow Overview

## Primary User Journey
```
[Home / Active Trip]
     |
     | start trip
     v
[Trip In Progress Overlay]
     |
     | stop trip
     v
[Trip Summary Dialog] --(save)--> [History List]
                               \--(discard)--> [Home]
```

## Screen Details
- **Home Screen**
  - Primary CTA: Start/Stop button toggling trip state.
  - Status text displaying elapsed time and active vehicle.
  - Quick link to switch vehicles.
- **Trip In Progress Overlay**
  - Shows live timer, signal strength indicator, and manual odometer slider.
  - Cancel option (requires confirmation) to avoid accidental stops.
- **Trip Summary Dialog**
  - Presents calculated distance, duration, and reverse geocoded start/end.
  - Allows tagging (Business/Personal/Commute/Other) before committing.
- **History List Screen**
  - Chronological list with cards summarizing trips.
  - Filter chips for tag type and vehicle.
  - Action menu for export and detail view.
- **Vehicle Manager Screen**
  - Table/list of vehicles with add/edit modals.
  - Default vehicle selection persisted across sessions.
- **Settings Screen**
  - CSV export button.
  - Placeholder section for future Google Sheets sync.
  - Privacy and permissions overview.

## Navigation Notes
- Bottom navigation with tabs: Home, History, Vehicles, Settings.
- Trip summary presented as modal to maintain context.
- Deep links should open specific trip details when implemented.


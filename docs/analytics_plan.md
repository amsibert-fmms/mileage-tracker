# Trip analytics plan

## Objectives
- Deliver richer insights on trip behaviour so drivers can optimise their mileage and reimbursements.
- Support exportable analytics that integrate with accounting and tax workflows.

## Immediate priorities
1. **Persist raw trip data.**
   - Capture trip start/stop events with location snapshots and store them locally using `sqflite`.
   - Add migration helpers in `lib/services` to manage schema evolution.
2. **Introduce category dashboards.**
   - Build reusable chart widgets under `lib/widgets` for bar and line visualisations.
   - Surface weekly and monthly summaries alongside the existing breakdown card.
3. **Enable data export.**
   - Implement CSV generation in a new `lib/services/export_service.dart`.
   - Provide a share sheet on `HomeScreen` to email or save reports.

## Research backlog
- Evaluate GPS sampling strategies to balance accuracy with battery usage.
- Review third-party services for automatic odometer capture.
- Prototype a web dashboard that mirrors the mobile analytics experience.

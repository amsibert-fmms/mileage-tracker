# Mileage Tracker

A new Flutter project built in Flutter and Dart.
---

🧭 Mileage Tracker App – Requirements & Scope Document (Draft)

1. Purpose & Vision

A simple, low-friction mobile and web app that lets self-employed drivers, technicians, and small business owners log mileage automatically or semi-automatically with as little manual input as possible.
The goal is ease + ownership — minimal effort to capture accurate data, stored locally or synced to a private spreadsheet.


---

2. Core Features (MVP)

🚘 Trip Logging

Start/Stop button widget

Single tap to start a trip → logs timestamp and GPS start coordinates

Single tap to stop → logs timestamp and GPS end coordinates


Automatic calculation of trip duration, distance estimate, and average speed


📍 Location & GPS

Use on-demand GPS (not constant tracking) to reduce battery use

Reverse-geocode coordinates into human-readable locations (“Home Depot, Champaign, IL”)

Fallback for no-signal environments → queue GPS reads when service resumes


🧾 Mileage & Vehicle

Default “active vehicle” selection (editable)

Optional odometer entry (estimated + manual correction slider)

Maintain list of vehicles with plate, make/model, and notes


📅 Data & Storage

Store trips in local SQLite DB (or secure file)

Export all trip data as CSV

Optional Google Sheets integration for automatic backup or syncing

Uses user’s own Google account via OAuth2



🏷️ Classification

Tag each trip as Business, Personal, Commute, or Other

Optional tagging rules (default based on location pairs)



---

3. Future Enhancements

🔄 Background “Auto-Trip Mode” using motion detection or Bluetooth triggers

🧮 Built-in tax deduction estimator

☁️ Multi-device sync (Firebase or Sheets)

🗺️ Map visualizations of routes

📊 Analytics (total mileage, business %, time spent driving)



---

4. Target Platforms

Primary: Android (via Flutter app)

Secondary: Flutter Web (for reports and data entry review)



---

5. Technical Architecture

Layer	Description

Frontend	Flutter 3.35.5 (Material 3 UI, responsive layout)
Backend	Local SQLite (via sqflite plugin); optional Google Sheets API integration
GPS	geolocator + geocoding packages
Export	CSV builder or direct Google Sheets sync
Auth (optional)	Google Sign-In for cloud features
Build/Deploy	GitHub Actions → Pages (web); Android Studio → Play Store (mobile)



---

6. Non-Functional Goals

🕒 Speed: One-tap logging, no background lag

🔒 Privacy: No external servers unless explicitly authorized by user

🔋 Efficiency: Location access only during active trip

💾 Reliability: Data saved locally before any sync

🎨 Simplicity: Intuitive enough for non-technical users



---

7. Out-of-Scope (MVP)

Multi-user accounts

Continuous background tracking

Cloud-only storage

Full tax report generator

Vehicle maintenance logs (possible later module)



---

8. Success Criteria

A user can start/stop trips accurately with <5 seconds delay

GPS resolves valid start/stop locations 90% of the time

Exports open cleanly in Google Sheets

Average session battery drain <5% per hour

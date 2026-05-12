# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `Neighborly.xcodeproj` in Xcode. Build and run via Xcode (⌘R) targeting a simulator or device. No CLI build tooling is configured.

Dependencies are managed via Swift Package Manager — Xcode resolves them automatically on first open.

## Architecture

Early-stage iOS app (SwiftUI + Firebase iOS SDK 12.13.0).

**Entry point:** `NeighborlyApp.swift` — uses `UIApplicationDelegateAdaptor` to wire `AppDelegate` for `FirebaseApp.configure()` at launch.

**Data layer:** Firebase Firestore. Direct `Firestore.firestore()` calls currently live in views; no repository/service layer yet.

**Models:** `Neighborly/Models/` — `NEIOffer.swift` defines `Offer` (Identifiable, Codable). Uses `CLLocationCoordinate2D` computed from stored `latitude`/`longitude` doubles. `id` is optional (assigned by Firestore on write).

**Firebase config:** `GoogleService-Info.plist` in the app target — do not commit changes to this file with real credentials.

## Key Conventions

- Model file prefix: `NEI` (e.g. `NEIOffer.swift` contains `struct Offer`)
- Location stored as raw `Double` lat/lon on the model; `CLLocationCoordinate2D` exposed as computed property
- Comments in Polish (codebase author is Polish-speaking)

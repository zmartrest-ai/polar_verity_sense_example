# Background Job Example

A minimal Flutter example to test background job functionality.

## Overview

This project demonstrates how to implement background jobs in Flutter using:

- **Workmanager** for Android
- **BackgroundFetch** for iOS

## Features

- Simple UI to trigger a test background job
- Periodic background tasks (every 15 minutes)
- One-off background tasks
- Debug logging

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run the app on an Android or iOS device
4. Press the "Run Test Background Job" button to trigger a one-off background job

## Implementation Details

- `lib/main.dart`: Main application entry point and UI
- `lib/background_job/background_job.dart`: Background job implementation

## Notes

- On Android, background jobs are implemented using the Workmanager plugin
- On iOS, background jobs are implemented using the BackgroundFetch plugin
- Background jobs have platform-specific limitations and behaviors

# Khata Ledger

Khata Ledger is a modern Flutter-based mobile application designed for small business owners and their customers to manage credit-ledger relationships digitally. The app helps owners track customer balances, record transactions, and monitor outstanding dues, while giving customers a simple way to view their account history and stay informed.

## Overview

This application provides a role-based experience for two user types:

- Owners: manage customers, monitor balances, create ledger entries, view summaries, and export business insights.
- Customers: view their personal transaction history and stay updated on account activity.

The app is built with a clean, modular architecture and is intended to work alongside a backend service for authentication, ledger data, and notifications.

## Key Features

- Secure authentication and onboarding for business owners
- Customer management and ledger tracking
- Transaction history for both owners and customers
- Dashboard summaries and outstanding balance insights
- Reports and export support for business data
- Push notifications for important updates
- Responsive and polished cross-platform UI built with Flutter
- Local secure storage for session persistence

## Technology Stack

- Flutter
- Dart
- Provider for state management
- Firebase Core and Firebase Messaging
- Flutter Secure Storage
- HTTP client for API communication
- fl_chart for visual analytics
- intl, path_provider, share_plus for app utilities

## Project Structure

- lib/main.dart: application bootstrap and role-based entry
- lib/config/: app-wide configuration and constants
- lib/core/: shared services, storage, and core utilities
- lib/data/: repositories and remote data sources
- lib/domain/: entities and business contracts
- lib/presentation/: screens, widgets, routes, and view models
- lib/services/: app services such as exports and dependency wiring

## Prerequisites

Before running the project, ensure that you have the following installed:

- Flutter SDK (recommended version compatible with the project)
- Android Studio or VS Code with Flutter extensions
- A device emulator or physical device
- Optional: Firebase configuration for push notifications and backend connectivity

## Installation

1. Clone the repository
2. Navigate to the app folder:
   ```bash
   cd App
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Common Development Commands

- Run tests:
  ```bash
  flutter test
  ```

- Analyze the project:
  ```bash
  flutter analyze
  ```

- Run on a specific platform:
  ```bash
  flutter run -d chrome
  ```

## Backend Integration

This frontend app is designed to communicate with a backend service for:

- User authentication
- Customer and ledger management
- Notification delivery
- Report and export operations

Ensure the backend API endpoints are configured correctly before using production workflows.

## App Experience

The application is structured around a simple and practical workflow:

1. An owner registers and signs in.
2. The owner adds customers and records transactions.
3. Customers can access their account data and activity history.
4. Owners can monitor outstanding balances and business performance.

## Contribution Guidelines

Contributions are welcome. If you would like to improve the app, please:

- Create a feature branch
- Make focused changes
- Verify the app works locally
- Submit a clear pull request with context and screenshots when relevant

## License

This project does not currently include a license file. Add an appropriate open-source or proprietary license before distributing it publicly.

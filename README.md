# Khata Ledger

Khata Ledger is a full-stack digital ledger application built for small businesses to manage customer credit, payments, and account activity in a simple and modern way. The project combines a Flutter mobile app with a Node.js backend to support both business owners and customers.

## Project Overview

This repository contains two main parts:

- App/: a Flutter-based mobile application for owners and customers
- backend/: a Node.js, Express, and MongoDB API that powers authentication, ledger operations, reports, and notifications

The system is designed to help shop owners keep track of balances and transactions without relying on paper records.

## Core Features

- Secure owner and customer authentication
- Customer management and ledger tracking
- Transaction recording for purchases, payments, and dues
- Outstanding balance monitoring
- Dashboard insights and reporting
- Notification support for important account updates
- Secure local storage for app sessions
- REST API integration between the mobile app and backend services

## Technology Stack

### Mobile App
- Flutter
- Dart
- Provider for state management
- Firebase Core and Firebase Messaging
- Flutter Secure Storage
- HTTP, intl, path_provider, share_plus, fl_chart

### Backend
- Node.js
- Express.js
- MongoDB with Mongoose
- JWT authentication
- Firebase Admin SDK
- Swagger documentation
- Jest and Supertest for testing

## Project Structure

```text
my_store/
├── App/              # Flutter frontend
├── backend/          # Node.js backend API
└── demo video/       # Project demo assets
```

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed and configured
- Node.js and npm installed
- MongoDB running or access to a MongoDB instance
- A device emulator or physical device for the mobile app

## Getting Started

### 1. Run the Flutter App

```bash
cd App
flutter pub get
flutter run
```

### 2. Run the Backend

```bash
cd backend
npm install
npm run dev
```

The backend API will typically run on:

```text
http://localhost:5000/api
```

## Environment Configuration

The backend requires environment variables such as:

- MongoDB connection string
- JWT secret keys
- CORS configuration
- Optional Firebase configuration for push notifications

Create a local environment file with the required values before starting the backend.

## Development Workflow

- Use the Flutter app for owner and customer-facing mobile workflows
- Use the backend for data storage, business logic, and API access
- Keep frontend and backend changes aligned when modifying shared behaviors

## Testing

### Frontend

```bash
cd App
flutter test
```

### Backend

```bash
cd backend
npm test
```

## Notes

This project is structured for practical business use and can be extended with additional features such as analytics, richer reporting, role-based permissions, and deployment automation.

## License

A project-wide license has not been added yet. If you plan to distribute or share this project publicly, it is recommended to add an appropriate license file.

## Frontend README.md

```markdown
# Bus Tracking System - Flutter Mobile App

A real-time bus tracking system mobile application built with Flutter to provide passengers with the ability to track buses, view schedules, and make payments.

## Overview

This Flutter application provides a user-friendly interface for passengers to track buses in real-time, view bus schedules, and make payments for their journey. It supports multiple languages and provides a seamless experience across different platforms.

## Features

- **User Authentication**
  - User registration and login
  - Password recovery
  - Profile management

- **Real-time Bus Tracking**
  - Live location tracking on map
  - Estimated arrival times
  - Bus route visualization

- **Schedule Management**
  - View bus schedules
  - Favorite routes
  - Journey planning

- **Payment System**
  - Secure in-app payments
  - Payment history
  - Receipt generation

- **Additional Features**
  - Multi-language support
  - Dark/Light theme switching
  - Offline capabilities

## Technology Stack

- **Framework**: Flutter (SDK 3.6.1+)
- **State Management**: Provider
- **Maps and Location**: Google Maps Flutter, Geolocator
- **Network**: HTTP package, WebSockets
- **Storage**: Shared Preferences
- **UI Components**: Material Design, Custom Widgets

## Getting Started

### Prerequisites

- Flutter SDK (3.6.1 or higher)
- Android Studio / Visual Studio Code
- Android SDK / Xcode (for iOS development)
- Google Maps API Key

### Installation

1. Clone the repository

### ```bash
git clone <repository-url>
cd Frontend/to_do

2. Install dependencies

flutter pub get

3. Configure API Keys

Create a file lib/config/config.dart with your API keys (see config.sample.dart for example)

4. Run the application

flutter run

### Project Structure
Frontend/to_do/
├── android/             # Android-specific files
├── ios/                 # iOS-specific files
├── lib/                 # Dart source code
│   ├── config/          # App configuration
│   ├── l10n/            # Localization files
│   ├── models/          # Data models
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   │   ├── auth/        # Authentication screens
│   │   ├── home/        # Home and dashboard screens
│   │   ├── maps/        # Map and tracking screens
│   │   ├── payments/    # Payment screens
│   │   └── settings/    # App settings screens
│   ├── services/        # API services
│   ├── utils/           # Utility functions
│   │   ├── constants.dart   # App constants
│   │   └── helpers.dart     # Helper functions
│   ├── widgets/         # Reusable widgets
│   └── main.dart        # Application entry point
├── assets/              # Static assets
│   ├── fonts/           # Custom fonts
│   ├── images/          # Images and icons
│   └── translations/    # Translation files
├── pubspec.yaml         # Dependencies and app metadata
└── README.md            # Project documentation

### Screens and Navigation

# Authentication Flow

Language Selection
Login
Registration (Passenger/Driver)
Password Reset

# Main App Flow

Home Screen with upcoming journeys
Map Screen for real-time tracking
Schedule Screen to view and search schedules
Profile Screen for user information
Settings Screen for app configuration

# Localization
The app supports multiple languages through Flutter's built-in localization system:

English (default)
French
Spanish
Arabic
Language files are stored in lib/l10n/ directory, and the app will automatically use the device's language if supported.

# Theming
The app supports both light and dark themes, which can be:

Set manually in the settings
Follow system settings
Scheduled based on time of day

# Configuration
The app uses environment-specific configuration for API endpoints and keys:

// Example config structure
class ApiConfig {
  static const String baseUrl = 'https://api.bustrack.com';
  static const String mapsApiKey = 'YOUR_MAPS_API_KEY';
}

# State Management
The app uses the Provider pattern for state management:

AuthProvider: Manages authentication state
LocationProvider: Handles location tracking
ScheduleProvider: Manages schedule data
ThemeProvider: Controls app theme

# Connectivity Handling
The app handles network connectivity issues gracefully:

Caches important data for offline use
Shows appropriate error messages during connectivity loss
Automatically retries operations when connectivity is restored

# Building for Production

Android
flutter build apk --release
The APK will be available at build/app/outputs/flutter-apk/app-release.apk

iOS
flutter build ios --release
Open the generated Xcode project and archive for App Store submission.

# Contributing

1. Fork the repository
2. Create your feature branch (git checkout -b feature/amazing-feature)
3. Commit your changes (git commit -m 'Add some amazing feature')
4. Push to the branch (git push origin feature/amazing-feature)
5. Open a Pull Request

# License
This project is proprietary software. All rights reserved.
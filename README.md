# Real-Time Bus Tracking System

A comprehensive real-time bus tracking application that consists of a Node.js/Express backend and Flutter mobile frontend. This system allows passengers to track buses in real-time, check schedules, and make secure payments.

## Project Overview

This project is divided into two main components:

1. **Backend**: A RESTful API server built with Node.js, Express, MongoDB, and Socket.IO
2. **Frontend**: A cross-platform mobile application built with Flutter

## Backend

### Technologies Used

- **Server**: Node.js, Express.js
- **Database**: MongoDB with Mongoose ODM
- **Real-time Communication**: Socket.IO
- **Authentication**: JWT (JSON Web Tokens)
- **Payment Processing**: PayPal SDK
- **Security**: Helmet, CORS
- **Logging**: Custom logger with file-based logging

### Key Features

- User authentication (drivers and passengers)
- Real-time vehicle tracking
- Route and schedule management
- Payment processing
- Journey tracking and status updates

### Project Structure

Backend/ ├── api/ # API routes organized by resource │ ├── auth/ # Authentication routes │ ├── routes/ # Bus routes endpoints │ ├── schedules/ # Schedule endpoints │ ├── users/ # User management endpoints │ └── vehicles/ # Vehicle management endpoints ├── config/ # Configuration files │ ├── db.js # Database configuration │ ├── maps.js # Google Maps configuration │ └── paypal.js # PayPal configuration ├── controllers/ # Business logic for routes ├── logs/ # Application logs ├── middleware/ # Express middleware ├── model/ # MongoDB models ├── routers/ # Route definitions ├── services/ # Business logic services ├── sockets/ # Socket.IO event handlers ├── utils/ # Utility functions ├── .env # Environment variables (not in repo) ├── app.js # Express application setup ├── index.js # Router entry point ├── package.json # Project dependencies └── server.js # Main server entry point

### Getting Started with Backend

1. **Prerequisites**

   - Node.js (v14 or higher)
   - MongoDB (local or Atlas)
   - PayPal Developer Account (for payment features)

2. **Installation**

### ```bash

### Clone the repository

git clone <repository-url>
cd Backend

### Install dependencies

npm install

### Set up environment variables

### Create a .env file with the following variables:

PORT=3001
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/bus-tracking-system
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
CLIENT_URL=http://localhost:3000
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

### Start the development server

npm run dev

## API Documentation

### Authentication Endpoints

POST /api/auth/driver/register - Register a new driver
POST /api/auth/driver/login - Login as a driver
POST /api/auth/passenger/register - Register a new passenger
POST /api/auth/passenger/login - Login as a passenger
POST /api/auth/forgot-password - Request password reset
POST /api/auth/reset-password - Reset password with token
### User Management
GET /api/users/driver/profile - Get driver profile
GET /api/users/passenger/profile - Get passenger profile
PUT /api/users/driver/profile - Update driver profile
PUT /api/users/passenger/profile - Update passenger profile
PUT /api/users/password - Change user password
### Routes
GET /api/routes - List all routes
GET /api/routes/:id - Get route details
POST /api/routes - Create a new route (admin/driver only)
PUT /api/routes/:id - Update a route (admin/driver only)
DELETE /api/routes/:id - Delete a route (admin only)
### Schedules
GET /api/schedules - List all schedules
GET /api/schedules/:id - Get schedule details
POST /api/schedules - Create a new schedule (admin only)
PUT /api/schedules/:id - Update a schedule (admin only)
DELETE /api/schedules/:id - Delete a schedule (admin only)
### Journeys
POST /api/journeys/start - Start a journey (driver only)
PUT /api/journeys/:id/update-location - Update journey location (driver only)
PUT /api/journeys/:id/complete - Complete a journey (driver only)
GET /api/journeys/active - Get active journeys
GET /api/journeys/:id - Get journey details
### Payments
POST /api/payments/create - Create a payment
GET /api/payments/success - Payment success callback
GET /api/payments/cancel - Payment cancel callback
GET /api/payments/history - Get payment history

# Frontend (Mobile App)
### Technologies Used
Framework: Flutter
State Management: Provider
Maps and Location: Google Maps Flutter, Geolocator
Network: HTTP package, WebSockets
Storage: Shared Preferences
UI Components: Material Design, Custom Widgets
### Key Features
User registration and authentication
Real-time bus tracking on map
Schedule viewing and journey planning
Secure in-app payments
Multi-language support
Dark/Light theme switching
### Project Structure
Frontend/to_do/
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
│   │   ├── constants.dart  # App constants
│   │   └── helpers.dart    # Helper functions
│   ├── widgets/         # Reusable widgets
│   └── main.dart        # Application entry point
├── assets/              # Static assets
│   ├── fonts/           # Custom fonts
│   ├── images/          # Images and icons
│   └── translations/    # Translation files
└── pubspec.yaml         # Dependencies and app metadata

# Getting Started with Frontend
### Prerequisites

Flutter SDK (3.0.0 or higher)
Android Studio / Visual Studio Code
Android SDK / Xcode (for iOS development)
Google Maps API Key

### Installation
### Navigate to the Flutter project directory
cd Frontend/to_do

### Install dependencies
flutter pub get

### Configure API keys
### Create config file at lib/config/config.dart with your API keys

### Run the application
flutter run

## Main App Features
1. Authentication

User login and registration
Role-based access (passenger/driver)
Password recovery

2. Passenger Features

View available bus routes
Track bus location in real-time
View estimated arrival times
Make payments for journeys
Receive notifications about bus status

3. Driver Features

Update bus location in real-time
Start and end journeys
View assigned routes and schedules
Receive passenger pickup notifications

4. Maps and Navigation

Real-time bus location tracking
Route visualization
Current location tracking
Estimated time of arrival calculations

5. Settings and Preferences

Language selection
Theme customization (dark/light mode)
Notification preferences
Account management

## Development and Deployment
### Development Environment

* Backend: Node.js development server with Nodemon for auto-reload
* Frontend: Flutter development with hot reload

## Deployment
### Backend Deployment
Deploy to a Node.js hosting service (Heroku, DigitalOcean, AWS)
Set up MongoDB Atlas for database
Configure environment variables for production

### Frontend Deployment
Build Android APK: flutter build apk --release
Build iOS IPA: Use Xcode to archive and distribute
Publish to app stores following the respective guidelines

### Contributing
1. Fork the repository
2. Create your feature branch (git checkout -b feature/amazing-feature)
3. Commit your changes (git commit -m 'Add some amazing feature')
4. Push to the branch (git push origin feature/amazing-feature)
5. Open a Pull Request

### License
### ISC

# Contact
For questions or support, please contact the project maintainers.


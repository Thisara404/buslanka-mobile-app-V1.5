# Bus Tracking System - Backend

A real-time bus tracking system backend built with Node.js, Express, MongoDB, and Socket.IO.

## Overview

This backend provides a complete API for a bus tracking system, allowing passengers to track buses in real-time, check schedules, and make payments. It provides authentication for both drivers and passengers, real-time location updates, and secure payment processing.

## Features

- **User Authentication**
  - Separate authentication for passengers and drivers
  - JWT-based authentication
  - Password reset functionality
  - Profile management

- **Real-time Tracking**
  - Socket.IO integration for real-time updates
  - Driver location broadcasting
  - Journey status updates

- **Route Management**
  - Route creation and listing
  - Schedule management
  - Favorite routes for passengers

- **Payment Processing**
  - PayPal integration
  - Secure payment handling
  - Payment history and receipts

## Technology Stack

- **Server**: Node.js, Express.js
- **Database**: MongoDB with Mongoose
- **Real-time Communication**: Socket.IO
- **Authentication**: JWT (JSON Web Tokens)
- **Payment Processing**: PayPal SDK
- **Security**: Helmet, CORS
- **Logging**: Custom logger with file-based logging

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or Atlas)
- PayPal Developer Account (for payment features)

### Installation

1. Clone the repository

### ```bash
git clone [<repository-url>](https://github.com/Thisara404/buslanka-mobile-app-V1.5.git)
cd Backend

2. Install dependencies
npm install

3. Create a .env file in the root directory with the following variables:

# Server
PORT=3001
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/bus-tracking-system

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

# Frontend URL (for CORS)
CLIENT_URL=http://localhost:3000

# PayPal
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

4. Start the development server

### API Documentation

# Authentication
# Driver Authentication
POST /api/auth/driver/register - Register a new driver
POST /api/auth/driver/login - Login as a driver
POST /api/auth/driver/forgot-password - Request password reset
POST /api/auth/driver/reset-password - Reset password with token
GET /api/auth/driver/validate-token - Validate driver JWT token
# Passenger Authentication
POST /api/auth/passenger/register - Register a new passenger
POST /api/auth/passenger/login - Login as a passenger
POST /api/auth/passenger/forgot-password - Request password reset
POST /api/auth/passenger/reset-password - Reset password with token
GET /api/auth/passenger/validate-token - Validate passenger JWT token
# User Management
GET /api/users/driver/profile - Get driver profile
GET /api/users/passenger/profile - Get passenger profile
PUT /api/users/driver/profile - Update driver profile
PUT /api/users/passenger/profile - Update passenger profile
PUT /api/users/password - Change user password
# Routes
GET /api/routes - List all routes
GET /api/routes/:id - Get route details
POST /api/routes - Create a new route (admin/driver only)
PUT /api/routes/:id - Update a route (admin/driver only)
DELETE /api/routes/:id - Delete a route (admin only)
# Schedules
GET /api/schedules - List all schedules
GET /api/schedules/:id - Get schedule details
POST /api/schedules - Create a new schedule (admin only)
PUT /api/schedules/:id - Update a schedule (admin only)
DELETE /api/schedules/:id - Delete a schedule (admin only)
# Payments
POST /api/payments/create - Create a payment
GET /api/payments/success - Payment success callback
GET /api/payments/cancel - Payment cancel callback
GET /api/payments/history - Get payment history
# Journeys
POST /api/journeys/start - Start a journey (driver only)
PUT /api/journeys/:id/update-location - Update journey location (driver only)
PUT /api/journeys/:id/complete - Complete a journey (driver only)
GET /api/journeys/active - Get active journeys
GET /api/journeys/:id - Get journey details
# Socket Events
# Server to Client
location_update - Real-time location update of a bus
journey_status_change - Journey status updates (started, completed, etc.)
bus_arrival - Notification when bus is arriving at a stop
# Client to Server
driver_location - Driver sends current location
join_journey - Passenger joins a journey for updates
leave_journey - Passenger leaves journey updates
# Middleware
auth.js - Authentication middleware with JWT verification
validation.js - Request validation middleware
errorHandler.js - Global error handling middleware
# Project Structure
Backend/
├── api/                # API routes organized by resource
│   ├── auth/           # Authentication routes
│   ├── routes/         # Bus routes endpoints
│   ├── schedules/      # Schedule endpoints
│   ├── users/          # User management endpoints
│   └── vehicles/       # Vehicle management endpoints
├── config/             # Configuration files
│   ├── db.js           # Database configuration
│   ├── maps.js         # Google Maps configuration
│   └── paypal.js       # PayPal configuration
├── controllers/        # Business logic for routes
├── logs/               # Application logs
├── middleware/         # Express middleware
├── model/              # MongoDB models
├── routers/            # Route definitions
├── services/           # Business logic services
├── sockets/            # Socket.IO event handlers
├── utils/              # Utility functions
├── .env                # Environment variables (not in repo)
├── app.js              # Express application setup
├── index.js            # Router entry point
├── package.json        # Project dependencies
└── server.js           # Main server entry point
# Error Handling
The application uses a centralized error handling approach with detailed logging:

Error responses follow a standard format: { status: false, message: "Error message", error: "Error details" }
All errors are logged to files in the /logs directory
Development mode includes more detailed error information
# License
# ISC

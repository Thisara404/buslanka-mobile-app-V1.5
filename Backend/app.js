const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const bodyParser = require('body-parser');
const connectDB = require('./config/db');

// Import routes
const authRoutes = require('./api/auth');
// const vehicleRoutes = require('./api/vehicles');
const routeRoutes = require('./api/routes');
const scheduleRoutes = require('./api/schedules');
const userRoutes = require('./api/users');
const paymentRoutes = require('./routers/payment.routes');
const journeyRoutes = require('./routers/journey.routes');

// Initialize express app
const app = express();

// Connect to database
connectDB();

// Middlewares
app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: true
}));
app.use(helmet());
app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Store io instance for use in routes
app.set('io', null);

// Middleware to make io available in route handlers
app.use((req, res, next) => {
  req.io = app.get('io');
  next();
});

// Routes
app.use('/api/auth', authRoutes);
// app.use('/api/vehicles', vehicleRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/users', userRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/journeys', journeyRoutes);

// Root route
app.get('/', (req, res) => {
  res.send('Bus Tracking API is running');
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    status: false, 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

module.exports = app;
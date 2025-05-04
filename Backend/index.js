const express = require('express');
const router = express.Router();

// Import auth routes
const driverAuthRoutes = require('./api/auth/driverAuth');
const passengerAuthRoutes = require('./api/auth/passengerAuth');

// Use routes
router.use('/driver', driverAuthRoutes);
router.use('/passenger', passengerAuthRoutes);

module.exports = router;
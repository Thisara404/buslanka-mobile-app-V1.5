const express = require('express');
const router = express.Router();

// Import auth routes
const driverAuthRoutes = require('./driverAuth');
const passengerAuthRoutes = require('./passengerAuth');

// Use routes
router.use('/driver', driverAuthRoutes);
router.use('/passenger', passengerAuthRoutes);

module.exports = router;
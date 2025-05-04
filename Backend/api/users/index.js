const express = require('express');
const router = express.Router();
const userController = require('../../controllers/user.controller');
const { verifyToken, authorize } = require('../../middleware/auth');

// All routes require authentication
router.use(verifyToken);

// Profile retrieval routes
router.get('/driver/profile', authorize(['driver']), userController.getDriverProfile);
router.get('/passenger/profile', authorize(['passenger']), userController.getPassengerProfile);

// Profile management routes
router.put('/driver/profile', authorize(['driver']), userController.updateDriverProfile);
router.put('/passenger/profile', authorize(['passenger']), userController.updatePassengerProfile);
router.put('/password', userController.changePassword);

// Favorite routes management (passenger only)
router.get('/favorites', authorize(['passenger']), userController.getPassengerFavorites);
router.post('/favorites/:action', authorize(['passenger']), userController.manageFavoriteRoute);

module.exports = router;
// const express = require('express');
// const router = express.Router();
// const vehicleController = require('../../controllers/vehicle.controller');
// const { verifyToken, authorize } = require('../../middleware/auth');

// // Public routes
// router.get('/', vehicleController.getAllVehicles);
// router.get('/:id', vehicleController.getVehicleById);
// router.get('/nearby', vehicleController.getNearbyVehicles); // Added to support passenger nearby vehicles feature

// // Protected routes - require authentication
// router.use(verifyToken);

// // Driver routes - more flexible with ID format for testing
// router.put('/:id/location', authorize(['driver']), vehicleController.updateVehicleLocation);
// // router.put('/:id/location', authorize(['driver']), vehicleController.updateVehicleLocation);
// // router.get('/driver/:id', authorize(['driver']), vehicleController.getDriverVehicle);
// // router.get('/driver/:id/location', authorize(['driver']), vehicleController.getDriverVehicleLocation);
// // router.get('/driver/:id/route', authorize(['driver']), vehicleController.getDriverVehicleRoute);
// // router.get('/driver/:id/route/locations', authorize(['driver']), vehicleController.getDriverVehicleRouteLocations);

// // router.get('/driver/:id/route/locations/:locationId', authorize(['driver']), vehicleController.getDriverVehicleRouteLocationById);
// // router.get('/driver/:id/route/locations/:locationId/next', authorize(['driver']), vehicleController.getNextLocationForDriver);
// // router.get('/driver/:id/route/locations/:locationId/previous', authorize(['driver']), vehicleController.getPreviousLocationForDriver);

// // router.post('/', authorize(['admin']), vehicleController.createVehicle);
// // router.put('/:id/status', authorize(['admin', 'driver']), vehicleController.updateVehicleStatus);
// // router.post('/assign', authorize(['admin']), vehicleController.assignVehicleToRoute);

// module.exports = router;
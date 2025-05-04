const express = require('express');
const router = express.Router();
const routeController = require('../../controllers/route.controller');
const { verifyToken, authorize } = require('../../middleware/auth');

// Public routes
router.get('/', routeController.getAllRoutes);
router.get('/search', routeController.searchRoutes);
router.get('/nearby', routeController.getRoutesNearLocation);
router.get('/:id', routeController.getRouteById);
router.get('/name/:name', routeController.getRouteByName);
router.get('/:id/directions', routeController.getRouteDirections);

// Protected routes - require authentication
router.use(verifyToken);

// Geocoding route - available to all authenticated users
router.post('/geocode', routeController.geocodeAddress);

// driver routes
router.post('/', authorize(['driver']), routeController.createRoute);
router.delete('/:id', authorize(['driver']), routeController.deleteRoute);
// router.put('/:id', authorize(['admin']), routeController.updateRoute);
// router.post('/optimize', authorize(['admin']), routeController.optimizeRouteOrder);

module.exports = router;
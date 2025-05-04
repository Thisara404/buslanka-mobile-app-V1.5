const Route = require('../model/Route');
const mongoose = require('mongoose');
const mapsUtils = require('../utils/mapsUtils');

// Get all routes
exports.getAllRoutes = async (req, res) => {
  try {
    const routes = await Route.find()
      .select('name description distance estimatedDuration');

    res.status(200).json({
      status: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    console.error('Error fetching routes:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch routes',
      error: error.message
    });
  }
};

// Get route by ID
exports.getRouteById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    const route = await Route.findById(id)
      .populate('schedules');

    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    res.status(200).json({
      status: true,
      data: route
    });
  } catch (error) {
    console.error('Error fetching route:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch route',
      error: error.message
    });
  }
};

// Get route by name
exports.getRouteByName = async (req, res) => {
  try {
    const { name } = req.params;
    
    const route = await Route.findOne({ name });

    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    res.status(200).json({
      status: true,
      data: route
    });
  } catch (error) {
    console.error('Error fetching route by name:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch route',
      error: error.message
    });
  }
};

// Get routes near a location
exports.getRoutesNearLocation = async (req, res) => {
  try {
    const { longitude, latitude, maxDistance = 2000 } = req.query;    
    if (!longitude || !latitude) {
      return res.status(400).json({
        status: false,
        message: 'Longitude and latitude are required'
      });
    }

    const coordinates = [parseFloat(longitude), parseFloat(latitude)];

    const routes = await Route.find({
      "stops.location": {
        $near: {
          $geometry: {
            type: "Point",
            coordinates
          },
          $maxDistance: parseInt(maxDistance)
        }
      }
    })
    .select('name description stops distance estimatedDuration');

    res.status(200).json({
      status: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    console.error('Error fetching nearby routes:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch nearby routes',
      error: error.message
    });
  }
};

// Search routes
exports.searchRoutes = async (req, res) => {
  try {
    const { keyword } = req.query;
    
    if (!keyword) {
      return res.status(400).json({
        status: false,
        message: 'Search keyword is required'
      });
    }

    const routes = await Route.find({
      $or: [
        { name: { $regex: keyword, $options: 'i' } },
        { description: { $regex: keyword, $options: 'i' } },
        { "stops.name": { $regex: keyword, $options: 'i' } }
      ]
    })
    .select('name description stops distance estimatedDuration');

    res.status(200).json({
      status: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    console.error('Error searching routes:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to search routes',
      error: error.message
    });
  }
};

// Create new route
exports.createRoute = async (req, res) => {
  try {
    const { name, description, stops, path, distance, estimatedDuration } = req.body;

    // Validate required fields
    if (!name || !stops || !stops.length || !path || !path.coordinates || !path.coordinates.length) {
      return res.status(400).json({
        status: false,
        message: 'Name, stops, and path coordinates are required'
      });
    }

    // Check if route name already exists
    const existingRoute = await Route.findOne({ name });
    if (existingRoute) {
      return res.status(400).json({
        status: false,
        message: 'Route name already exists'
      });
    }

    // Create new route
    const newRoute = new Route({
      name,
      description,
      stops,
      path,
      distance: distance || 0,
      estimatedDuration: estimatedDuration || 0
    });

    await newRoute.save();

    res.status(201).json({
      status: true,
      message: 'Route created successfully',
      data: newRoute
    });
  } catch (error) {
    console.error('Error creating route:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to create route',
      error: error.message
    });
  }
};

// Update route
exports.updateRoute = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, stops, path, distance, estimatedDuration } = req.body;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    // Update fields if provided
    if (name) route.name = name;
    if (description) route.description = description;
    if (stops) route.stops = stops;
    if (path && path.coordinates) {
      route.path = {
        type: 'LineString',
        coordinates: path.coordinates
      };
    }
    if (distance !== undefined) route.distance = distance;
    if (estimatedDuration !== undefined) route.estimatedDuration = estimatedDuration;

    await route.save();

    res.status(200).json({
      status: true,
      message: 'Route updated successfully',
      data: route
    });
  } catch (error) {
    console.error('Error updating route:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update route',
      error: error.message
    });
  }
};

// Optimize route order
exports.optimizeRouteOrder = async (req, res) => {
  try {
    const { originLng, originLat, destinationLng, destinationLat } = req.body;
    let { stops } = req.body;

    if (!stops || !Array.isArray(stops) || stops.length < 2) {
      return res.status(400).json({
        status: false,
        message: 'At least two stops are required for route optimization'
      });
    }

    // Parse coordinates
    const origin = [parseFloat(originLng), parseFloat(originLat)];
    const destination = [parseFloat(destinationLng), parseFloat(destinationLat)];
    
    // Convert stops to coordinates format
    const waypoints = stops.map(stop => [
      parseFloat(stop.longitude), 
      parseFloat(stop.latitude)
    ]);

    // Get optimized route
    const optimizedRoute = await mapsUtils.optimizeRoute(origin, destination, waypoints);

    res.status(200).json({
      status: true,
      message: 'Route optimized successfully',
      data: optimizedRoute
    });
  } catch (error) {
    console.error('Error optimizing route:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to optimize route',
      error: error.message
    });
  }
};

// Get route directions
exports.getRouteDirections = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    // Get the route
    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    // Extract the first and last stops
    const stops = route.stops;
    if (stops.length < 2) {
      return res.status(400).json({
        status: false,
        message: 'Route must have at least two stops to get directions'
      });
    }

    const origin = stops[0].location.coordinates;
    const destination = stops[stops.length - 1].location.coordinates;
    
    // Extract middle stops as waypoints
    const waypoints = stops.slice(1, -1).map(stop => stop.location.coordinates);

    // Get directions
    const directions = await mapsUtils.getDirections(origin, destination, waypoints);

    res.status(200).json({
      status: true,
      data: {
        routeId: id,
        routeName: route.name,
        directions
      }
    });
  } catch (error) {
    console.error('Error fetching route directions:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch route directions',
      error: error.message
    });
  }
};

// Geocode address
exports.geocodeAddress = async (req, res) => {
  try {
    const { address } = req.body;
    
    if (!address) {
      return res.status(400).json({
        status: false,
        message: 'Address is required'
      });
    }

    const result = await mapsUtils.geocodeAddress(address);
    
    res.status(200).json({
      status: true,
      data: result
    });
  } catch (error) {
    console.error('Error geocoding address:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to geocode address',
      error: error.message
    });
  }
};

// Delete route
exports.deleteRoute = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    await Route.findByIdAndDelete(id);

    res.status(200).json({
      status: true,
      message: 'Route deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting route:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to delete route',
      error: error.message
    });
  }
};
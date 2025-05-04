const UserService = require("../services/user.services");
const Driver = require('../model/Driver');
const Passenger = require('../model/Passenger');
const Route = require('../model/Route');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

exports.register = async (req, res, next) => {
  try {
    const { username, email, password } = req.body;
    const successResponse = await UserService.registerUser(
      username,
      email,
      password
    );
    return res.status(201).json({
      status: true,
      success: "User registered successfully",
      data: successResponse,
    });
  } catch (error) {
    return res.status(400).json({
      status: false,
      message: error.message
    });
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const successResponse = await UserService.loginUser(email, password);
    return res.status(200).json({
      status: true,
      success: "User logged in successfully",
      token: successResponse.token,
      data: successResponse,
    });
  } catch (error) {
    return res.status(400).json({
      status: false,
      message: error.message
    });
  }
};

// Update driver profile
exports.updateDriverProfile = async (req, res) => {
  try {
    const driverId = req.user.id;
    const { name, phone, email, address, image } = req.body;

    // Find driver
    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({
        status: false,
        message: 'Driver not found'
      });
    }

    // Check if email or phone is being changed and if it's already in use
    if (email && email !== driver.email) {
      const emailExists = await Driver.findOne({ email });
      if (emailExists) {
        return res.status(400).json({
          status: false,
          message: 'Email already in use'
        });
      }
      driver.email = email;
    }

    if (phone && phone !== driver.phone) {
      const phoneExists = await Driver.findOne({ phone });
      if (phoneExists) {
        return res.status(400).json({
          status: false,
          message: 'Phone number already in use'
        });
      }
      driver.phone = phone;
    }

    // Update other fields if provided
    if (name) driver.name = name;
    if (address) driver.address = address;
    if (image) driver.image = image;

    await driver.save();

    // Remove password from response
    const driverResponse = driver.toObject();
    delete driverResponse.password;

    res.status(200).json({
      status: true,
      message: 'Profile updated successfully',
      data: driverResponse
    });
  } catch (error) {
    console.error('Error updating driver profile:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update profile',
      error: error.message
    });
  }
};

// Update passenger profile
exports.updatePassengerProfile = async (req, res) => {
  try {
    const passengerId = req.user.id;
    const { name, phone, email, addresses, image } = req.body;

    // Find passenger
    const passenger = await Passenger.findById(passengerId);
    if (!passenger) {
      return res.status(404).json({
        status: false,
        message: 'Passenger not found'
      });
    }

    // Check if email or phone is being changed and if it's already in use
    if (email && email !== passenger.email) {
      const emailExists = await Passenger.findOne({ email });
      if (emailExists) {
        return res.status(400).json({
          status: false,
          message: 'Email already in use'
        });
      }
      passenger.email = email;
    }

    if (phone && phone !== passenger.phone) {
      const phoneExists = await Passenger.findOne({ phone });
      if (phoneExists) {
        return res.status(400).json({
          status: false,
          message: 'Phone number already in use'
        });
      }
      passenger.phone = phone;
    }

    // Update other fields if provided
    if (name) passenger.name = name;
    if (addresses) {
      // Merge addresses to keep existing ones that weren't updated
      passenger.addresses = {
        ...passenger.addresses,
        ...addresses
      };
    }
    if (image) passenger.image = image;

    await passenger.save();

    // Remove password from response
    const passengerResponse = passenger.toObject();
    delete passengerResponse.password;

    res.status(200).json({
      status: true,
      message: 'Profile updated successfully',
      data: passengerResponse
    });
  } catch (error) {
    console.error('Error updating passenger profile:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update profile',
      error: error.message
    });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        status: false,
        message: 'Current password and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        status: false,
        message: 'New password must be at least 6 characters long'
      });
    }

    // Find user based on role
    let user;
    if (userRole === 'driver') {
      user = await Driver.findById(userId);
    } else if (userRole === 'passenger') {
      user = await Passenger.findById(userId);
    }

    if (!user) {
      return res.status(404).json({
        status: false,
        message: 'User not found'
      });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({
        status: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    res.status(200).json({
      status: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to change password',
      error: error.message
    });
  }
};

// Add/remove favorite route for passenger
exports.manageFavoriteRoute = async (req, res) => {
  try {
    const passengerId = req.user.id;
    const { routeId } = req.body;
    const { action } = req.params; // 'add' or 'remove'
    
    if (!mongoose.Types.ObjectId.isValid(routeId)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    // Check if route exists
    const route = await Route.findById(routeId);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    // Find passenger
    const passenger = await Passenger.findById(passengerId);
    if (!passenger) {
      return res.status(404).json({
        status: false,
        message: 'Passenger not found'
      });
    }

    if (action === 'add') {
      // Check if route is already in favorites
      if (!passenger.favoriteRoutes.includes(routeId)) {
        passenger.favoriteRoutes.push(routeId);
        await passenger.save();
      }
      
      res.status(200).json({
        status: true,
        message: 'Route added to favorites'
      });
    } else if (action === 'remove') {
      // Remove route from favorites
      passenger.favoriteRoutes = passenger.favoriteRoutes.filter(
        id => id.toString() !== routeId
      );
      await passenger.save();
      
      res.status(200).json({
        status: true,
        message: 'Route removed from favorites'
      });
    } else {
      res.status(400).json({
        status: false,
        message: 'Invalid action. Use "add" or "remove"'
      });
    }
  } catch (error) {
    console.error('Error managing favorite routes:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to manage favorite routes',
      error: error.message
    });
  }
};

// Get passenger favorites
exports.getPassengerFavorites = async (req, res) => {
  try {
    const passengerId = req.user.id;

    const passenger = await Passenger.findById(passengerId)
      .populate('favoriteRoutes', 'name description distance estimatedDuration');

    if (!passenger) {
      return res.status(404).json({
        status: false,
        message: 'Passenger not found'
      });
    }
    
    res.status(200).json({
      status: true,
      count: passenger.favoriteRoutes.length,
      data: passenger.favoriteRoutes
    });
  } catch (error) {
    console.error('Error fetching favorite routes:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch favorite routes',
      error: error.message
    });
  }
};

// Get driver profile
exports.getDriverProfile = async (req, res) => {
  try {
    const driverId = req.user.id;
    console.log('Getting driver profile for ID:', driverId);

    // Find driver and exclude password
    const driver = await Driver.findById(driverId).select('-password');
    console.log('Driver found:', driver ? 'Yes' : 'No');
    
    if (!driver) {
      return res.status(404).json({
        status: false,
        message: 'Driver not found'
      });
    }

    // Create response object
    const driverData = driver.toObject();
    
    // Use busDetails directly from driver model
    // If driver has no busDetails, create default values
    if (!driverData.busDetails) {
      driverData.busDetails = {
        busNumber: 'Not assigned',
        busModel: 'Not assigned',
        busColor: 'Not assigned'
      };
    }

    // Get stats (can be expanded as needed)
    const Schedule = require('../model/Schedule');
    const completedTrips = await Schedule.countDocuments({
      driver: driverId,
      status: 'completed'
    });

    driverData.totalTrips = completedTrips || 0;
    driverData.rating = driver.rating || 4.5; // Default if not available
    driverData.joinDate = driver.createdAt ? 
      new Date(driver.createdAt).toISOString().split('T')[0] : 
      'Not available';

    res.status(200).json({
      status: true,
      message: 'Driver profile retrieved successfully',
      data: driverData
    });
  } catch (error) {
    console.error('Detailed error fetching driver profile:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch profile',
      error: error.message
    });
  }
};

// Get passenger profile
exports.getPassengerProfile = async (req, res) => {
  try {
    const passengerId = req.user.id;

    // Find passenger and exclude password
    const passenger = await Passenger.findById(passengerId).select('-password');
    
    if (!passenger) {
      return res.status(404).json({
        status: false,
        message: 'Passenger not found'
      });
    }

    res.status(200).json({
      status: true,
      message: 'Passenger profile retrieved successfully',
      data: passenger
    });
  } catch (error) {
    console.error('Error fetching passenger profile:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch profile',
      error: error.message
    });
  }
};

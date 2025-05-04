const Vehicle = require('../model/Vehicle');
const Schedule = require('../model/Schedule');
const Route = require('../model/Route');
const mongoose = require('mongoose');
const { calculateEstimatedArrival } = require('../utils/timeUtils');

// Store connected users
const connectedUsers = {
  drivers: new Map(), // Map of driverId -> socketId
  passengers: new Map() // Map of passengerId -> socketId
};

// Socket.IO handler
module.exports = (io) => {
  // Middleware for authentication
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    
    if (!token) {
      return next(new Error('Authentication error: Token required'));
    }
    
    try {
      // Verify JWT token
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Attach user data to socket
      socket.user = decoded;
      
      // If user is authenticated, proceed
      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      return next(new Error('Authentication error: Invalid token'));
    }
  });

  // Handle connection
  io.on('connection', async (socket) => {
    console.log(`Socket connected: ${socket.id}`);
    
    const userId = socket.user?.id;
    const userRole = socket.user?.role;

    // Register user connection
    if (userId && userRole) {
      if (userRole === 'driver') {
        connectedUsers.drivers.set(userId, socket.id);
        console.log(`Driver ${userId} connected`);
        
        // Join driver-specific room
        socket.join(`driver:${userId}`);
      } else if (userRole === 'passenger') {
        connectedUsers.passengers.set(userId, socket.id);
        console.log(`Passenger ${userId} connected`);
        
        // Join passenger-specific room
        socket.join(`passenger:${userId}`);
        
        // Try to load passenger favorites to auto-subscribe
        try {
          const Passenger = require('../model/Passenger');
          const passenger = await Passenger.findById(userId);
          
          if (passenger && passenger.favoriteRoutes?.length) {
            // Auto-subscribe to favorite routes
            passenger.favoriteRoutes.forEach(routeId => {
              socket.join(`route:${routeId}`);
            });
            
            socket.emit('favorites:subscribed', {
              count: passenger.favoriteRoutes.length,
              message: 'Auto-subscribed to your favorite routes'
            });
          }
        } catch (error) {
          console.error(`Error setting up passenger ${userId} rooms:`, error);
        }
      }
    }

    // Enhanced route subscription
    socket.on('route:subscribe', async (data) => {
      try {
        const { routeId } = data;
        
        if (!routeId || !mongoose.Types.ObjectId.isValid(routeId)) {
          socket.emit('error', { message: 'Valid route ID is required' });
          return;
        }

        // Check if route exists
        const route = await Route.findById(routeId);
        if (!route) {
          socket.emit('error', { message: 'Route not found' });
          return;
        }

        socket.join(`route:${routeId}`);
        
        socket.emit('route:subscribed', { 
          routeId, 
          message: 'Successfully subscribed to route updates' 
        });
        
        // Add to passenger favorites if it's a passenger
        if (userRole === 'passenger' && userId) {
          try {
            const Passenger = require('../model/Passenger');
            const passenger = await Passenger.findById(userId);
            
            if (passenger && !passenger.favoriteRoutes.includes(routeId)) {
              // Prompt user to add to favorites
              socket.emit('favorites:suggestion', {
                routeId,
                routeName: route.name,
                message: 'Would you like to add this route to your favorites?'
              });
            }
          } catch (error) {
            console.error('Error checking passenger favorites:', error);
          }
        }
      } catch (error) {
        console.error('Error subscribing to route:', error);
        socket.emit('error', { message: 'Failed to subscribe to route' });
      }
    });

    // Enhanced schedule subscription
    socket.on('schedule:subscribe', async (data) => {
      try {
        const { scheduleId } = data;
        
        if (!scheduleId || !mongoose.Types.ObjectId.isValid(scheduleId)) {
          socket.emit('error', { message: 'Valid schedule ID is required' });
          return;
        }

        // Check if schedule exists
        const schedule = await Schedule.findById(scheduleId)
          .populate('routeId');
        
        if (!schedule) {
          socket.emit('error', { message: 'Schedule not found' });
          return;
        }

        socket.join(`schedule:${scheduleId}`);
        
        socket.emit('schedule:subscribed', { 
          scheduleId,
          schedule: {
            _id: schedule._id,
            routeId: schedule.routeId._id,
            routeName: schedule.routeId.name,
            status: schedule.status,
            startTime: schedule.startTime,
            endTime: schedule.endTime
          },
          message: 'Successfully subscribed to schedule updates' 
        });
      } catch (error) {
        console.error('Error subscribing to schedule:', error);
        socket.emit('error', { message: 'Failed to subscribe to schedule' });
      }
    });

    // Handle disconnect
    socket.on('disconnect', async () => {
      console.log(`Socket disconnected: ${socket.id}`);

      if (userId && userRole) {
        if (userRole === 'driver') {
          connectedUsers.drivers.delete(userId);
        } else if (userRole === 'passenger') {
          connectedUsers.passengers.delete(userId);
        }
      }
    });
  });
};
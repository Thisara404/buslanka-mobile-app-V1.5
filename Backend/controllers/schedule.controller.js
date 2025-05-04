const Schedule = require('../model/Schedule');
const Route = require('../model/Route');
const mongoose = require('mongoose');
const { calculateEstimatedArrival } = require('../utils/timeUtils');

// Get schedule by route
exports.getScheduleByRoute = async (req, res) => {
  try {
    const { routeId } = req.params;
    const { day, status } = req.query;
    
    if (!mongoose.Types.ObjectId.isValid(routeId)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    // Build query
    const query = { routeId };
    if (day) {
      query.dayOfWeek = day;
    }
    if (status) {
      query.status = status;
    }

    // Get current day of week if not specified
    const today = new Date();
    const currentDay = new Intl.DateTimeFormat('en-US', { weekday: 'long' }).format(today);
    
    // If no day specified, default to current day & upcoming days
    if (!day) {
      const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const todayIndex = daysOfWeek.indexOf(currentDay);
      
      // Include today and future days in the week
      const relevantDays = daysOfWeek.slice(todayIndex).concat(daysOfWeek.slice(0, todayIndex));
      query.dayOfWeek = { $in: relevantDays };
    }

    // Fetch schedules with population (removed vehicle population)
    const schedules = await Schedule.find(query)
      .populate('driverId', 'name phone')
      .sort({ startTime: 1 }); // Sort by start time

    if (!schedules.length) {
      return res.status(404).json({
        status: false,
        message: 'No schedules found for this route'
      });
    }

    // Get route details for stop-specific information
    const route = await Route.findById(routeId);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Route not found'
      });
    }

    // Enhance schedules with status information
    const enhancedSchedules = schedules.map(schedule => {
      const scheduleObj = schedule.toObject();
      
      // Calculate if this schedule is for today
      const isToday = schedule.dayOfWeek.includes(currentDay);
      
      // Check if the schedule's time has already passed for today
      const now = new Date();
      const scheduleTime = new Date(schedule.startTime);
      scheduleTime.setHours(schedule.startTime.getHours(), schedule.startTime.getMinutes());
      
      const isPassed = isToday && now > scheduleTime;
      
      // Add additional status info for the frontend
      return {
        ...scheduleObj,
        isToday,
        isPassed,
        formattedStartTime: schedule.startTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        formattedEndTime: schedule.endTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        stops: route.stops.map(stop => ({
          _id: stop._id,
          name: stop.name,
          location: stop.location,
          estimatedTime: scheduleObj.stopTimes.find(st => st.stopId.toString() === stop._id.toString())?.arrivalTime || null
        }))
      };
    });

    res.status(200).json({
      status: true,
      count: enhancedSchedules.length,
      data: enhancedSchedules
    });
  } catch (error) {
    console.error('Error fetching schedules:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch schedules',
      error: error.message
    });
  }
};

// Get schedule by ID
exports.getScheduleById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    const schedule = await Schedule.findById(id)
      .populate('routeId', 'name description stops')
      .populate('driverId', 'name phone');

    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Format times for readability
    const formattedSchedule = {
      ...schedule.toObject(),
      formattedStartTime: schedule.startTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
      formattedEndTime: schedule.endTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
    };

    res.status(200).json({
      status: true,
      data: formattedSchedule
    });
  } catch (error) {
    console.error('Error fetching schedule:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch schedule',
      error: error.message
    });
  }
};

// Get estimated arrival times
exports.getEstimatedArrivalTimes = async (req, res) => {
  try {
    const { scheduleId, stopId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(scheduleId)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    const schedule = await Schedule.findById(scheduleId).populate('routeId');
    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Calculate estimated arrival times for all stops or a specific stop
    // Since no vehicle tracking, use default schedule times
    const estimatedArrivals = await calculateEstimatedArrival(
      schedule, 
      null,  // vehicleLocation is now null since we don't track vehicles
      stopId ? stopId : null
    );

    res.status(200).json({
      status: true,
      data: {
        scheduleId: schedule._id,
        routeName: schedule.routeId.name,
        estimatedArrivals
      }
    });
  } catch (error) {
    console.error('Error calculating estimated arrival times:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to calculate estimated arrival times',
      error: error.message
    });
  }
};

// Update schedule
exports.updateSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const { driverId, dayOfWeek, startTime, endTime, stopTimes, status, isRecurring } = req.body;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    const schedule = await Schedule.findById(id);
    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Record previous status for comparison
    const previousStatus = schedule.status;
    
    if (driverId) {
      if (!mongoose.Types.ObjectId.isValid(driverId)) {
        return res.status(400).json({
          status: false,
          message: 'Invalid driver ID format'
        });
      }
      schedule.driverId = driverId;
    }
    
    if (dayOfWeek) schedule.dayOfWeek = dayOfWeek;
    if (startTime) schedule.startTime = new Date(startTime);
    if (endTime) schedule.endTime = new Date(endTime);
    if (stopTimes) schedule.stopTimes = stopTimes;
    if (status) schedule.status = status;
    if (isRecurring !== undefined) schedule.isRecurring = isRecurring;

    await schedule.save();

    // If Socket.IO is available, notify subscribers about the schedule update
    const io = req.app.get('io');
    if (io) {
      io.to(`schedule:${schedule._id}`).emit('schedule:updated', {
        scheduleId: schedule._id,
        status: schedule.status,
        updatedAt: new Date(),
        message: `Schedule has been updated to ${schedule.status}`
      });
    }

    res.status(200).json({
      status: true,
      message: 'Schedule updated successfully',
      data: schedule
    });
  } catch (error) {
    console.error('Error updating schedule:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update schedule',
      error: error.message
    });
  }
};

// Create new schedule
exports.createSchedule = async (req, res) => {
  try {
    const { routeId, driverId, dayOfWeek, startTime, endTime, stopTimes, isRecurring } = req.body;

    // Validate required fields
    if (!routeId || !dayOfWeek || !startTime || !endTime) {
      return res.status(400).json({
        status: false,
        message: 'Route ID, day of week, start time, and end time are required'
      });
    }

    // Validate route ID format
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

    // Create new schedule
    const newSchedule = new Schedule({
      routeId,
      dayOfWeek,
      startTime: new Date(startTime),
      endTime: new Date(endTime),
      status: 'scheduled',
      isRecurring: isRecurring !== undefined ? isRecurring : true
    });

    // Add driverId if provided
    if (driverId) {
      if (!mongoose.Types.ObjectId.isValid(driverId)) {
        return res.status(400).json({
          status: false,
          message: 'Invalid driver ID format'
        });
      }
      
      newSchedule.driverId = driverId;
    }

    // Add stop times if provided
    if (stopTimes && Array.isArray(stopTimes)) {
      // Format stop times with proper stop names from route
      const formattedStopTimes = stopTimes.map(st => {
        const stop = route.stops.find(s => s._id.toString() === st.stopId);
        return {
          stopId: st.stopId,
          stopName: stop ? stop.name : 'Unknown Stop',
          arrivalTime: new Date(st.arrivalTime),
          departureTime: new Date(st.departureTime || st.arrivalTime)
        };
      });
      
      newSchedule.stopTimes = formattedStopTimes;
    }

    await newSchedule.save();

    // Add schedule to route's schedules array if it exists
    if (route.schedules) {
      route.schedules.push(newSchedule._id);
      await route.save();
    }

    res.status(201).json({
      status: true,
      message: 'Schedule created successfully',
      data: newSchedule
    });
  } catch (error) {
    console.error('Error creating schedule:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to create schedule',
      error: error.message
    });
  }
};

// Get schedules by route ID
exports.getSchedulesByRoute = async (req, res) => {
  try {
    const { routeId } = req.params;
    const { day, status } = req.query;
    
    if (!mongoose.Types.ObjectId.isValid(routeId)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid route ID format'
      });
    }

    // Build query
    const query = { routeId };
    if (day) {
      query.dayOfWeek = day;
    }
    if (status) {
      query.status = status;
    }

    // Get current day of week
    const today = new Date();
    const currentDay = new Intl.DateTimeFormat('en-US', { weekday: 'long' }).format(today);
    
    // If no day specified, default to current day & upcoming days
    if (!day) {
      const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const todayIndex = daysOfWeek.indexOf(currentDay);
      
      // Include today and future days in the week
      const relevantDays = daysOfWeek.slice(todayIndex).concat(daysOfWeek.slice(0, todayIndex));
      query.dayOfWeek = { $in: relevantDays };
    }

    // Fetch schedules
    const schedules = await Schedule.find(query)
      .populate('routeId', 'name description stops')
      .populate('driverId', 'name phone')
      .sort({ startTime: 1 });

    if (!schedules.length) {
      return res.status(404).json({
        status: false,
        message: 'No schedules found for this route'
      });
    }

    // Enhance schedules with more information
    const enhancedSchedules = schedules.map(schedule => {
      const scheduleObj = schedule.toObject();
      
      // Calculate if this schedule is for today
      const isToday = schedule.dayOfWeek.includes(currentDay);
      
      // Check if the schedule's time has already passed for today
      const now = new Date();
      const scheduleTime = new Date(schedule.startTime);
      scheduleTime.setHours(schedule.startTime.getHours(), schedule.startTime.getMinutes());
      
      const isPassed = isToday && now > scheduleTime;
      
      return {
        ...scheduleObj,
        isToday,
        isPassed,
        formattedStartTime: schedule.startTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        formattedEndTime: schedule.endTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
      };
    });

    res.status(200).json({
      status: true,
      count: enhancedSchedules.length,
      data: enhancedSchedules
    });
  } catch (error) {
    console.error('Error fetching schedules:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch schedules',
      error: error.message
    });
  }
};

// Update schedule status specifically
exports.updateScheduleStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    if (!status || !['scheduled', 'in-progress', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({
        status: false,
        message: 'Valid status is required (scheduled, in-progress, completed, cancelled)'
      });
    }

    const schedule = await Schedule.findById(id);
    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Record previous status
    const previousStatus = schedule.status;
    
    // Update status
    schedule.status = status;
    await schedule.save();

    // Notify via socket.io if available
    const io = req.app.get('io');
    if (io) {
      io.to(`schedule:${schedule._id}`).emit('schedule:status:changed', {
        scheduleId: schedule._id,
        previousStatus,
        currentStatus: status,
        timestamp: new Date(),
        message: `Schedule status changed from ${previousStatus} to ${status}`
      });
      
      // If route exists, notify route subscribers too
      if (schedule.routeId) {
        io.to(`route:${schedule.routeId}`).emit('schedule:status:changed', {
          scheduleId: schedule._id,
          routeId: schedule.routeId,
          previousStatus,
          currentStatus: status,
          timestamp: new Date()
        });
      }
    }

    res.status(200).json({
      status: true,
      message: 'Schedule status updated successfully',
      data: {
        scheduleId: schedule._id,
        previousStatus,
        currentStatus: status,
        timestamp: new Date()
      }
    });
  } catch (error) {
    console.error('Error updating schedule status:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update schedule status',
      error: error.message
    });
  }
};

// Delete a schedule
exports.deleteSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    const schedule = await Schedule.findById(id);
    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Get the route to update its schedules array
    const route = await Route.findById(schedule.routeId);

    // Delete the schedule
    await Schedule.findByIdAndDelete(id);

    // Remove reference from route's schedules array
    if (route) {
      route.schedules = route.schedules.filter(
        scheduleId => scheduleId.toString() !== id
      );
      await route.save();
    }

    // Notify via socket.io if available
    const io = req.app.get('io');
    if (io) {
      io.to(`schedule:${id}`).emit('schedule:deleted', {
        scheduleId: id,
        routeId: schedule.routeId,
        timestamp: new Date(),
        message: 'Schedule has been deleted'
      });
    }

    res.status(200).json({
      status: true,
      message: 'Schedule deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting schedule:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to delete schedule',
      error: error.message
    });
  }
};

// Create or update stop times for a schedule
exports.createStopTimes = async (req, res) => {
  try {
    const { id } = req.params;
    const { stopTimes } = req.body;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    if (!stopTimes || !Array.isArray(stopTimes) || !stopTimes.length) {
      return res.status(400).json({
        status: false,
        message: 'Valid stopTimes array is required'
      });
    }

    const schedule = await Schedule.findById(id);
    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Get route to verify stops exist
    const route = await Route.findById(schedule.routeId);
    if (!route) {
      return res.status(404).json({
        status: false,
        message: 'Associated route not found'
      });
    }

    // Validate all stop IDs in stopTimes exist in the route
    const validStopIds = route.stops.map(stop => stop._id.toString());
    const allStopsValid = stopTimes.every(st => 
      validStopIds.includes(st.stopId.toString())
    );

    if (!allStopsValid) {
      return res.status(400).json({
        status: false,
        message: 'One or more stopIds do not exist in the associated route'
      });
    }

    // Format and validate stop times
    const formattedStopTimes = stopTimes.map(st => ({
      stopId: st.stopId,
      stopName: route.stops.find(s => s._id.toString() === st.stopId.toString())?.name || 'Unknown Stop',
      arrivalTime: new Date(st.arrivalTime),
      departureTime: new Date(st.departureTime || st.arrivalTime)
    }));

    // Ensure times are chronological
    formattedStopTimes.sort((a, b) => a.arrivalTime - b.arrivalTime);

    // Update schedule with new stop times
    schedule.stopTimes = formattedStopTimes;
    await schedule.save();

    // Notify via socket.io if available
    const io = req.app.get('io');
    if (io) {
      io.to(`schedule:${id}`).emit('schedule:stoptimes:updated', {
        scheduleId: id,
        routeId: schedule.routeId.toString(),
        timestamp: new Date(),
        message: 'Schedule stop times have been updated'
      });
    }

    res.status(200).json({
      status: true,
      message: 'Schedule stop times updated successfully',
      data: {
        scheduleId: schedule._id,
        stopTimes: schedule.stopTimes
      }
    });
  } catch (error) {
    console.error('Error updating schedule stop times:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to update schedule stop times',
      error: error.message
    });
  }
};

// Get schedule with fare information
exports.getScheduleWithFare = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        status: false,
        message: 'Invalid schedule ID format'
      });
    }

    const schedule = await Schedule.findById(id)
      .populate('routeId', 'name description stops distance costPerKm')
      .populate('driverId', 'name phone');

    if (!schedule) {
      return res.status(404).json({
        status: false,
        message: 'Schedule not found'
      });
    }

    // Calculate fare
    const baseFare = schedule.routeId.costPerKm 
      ? schedule.routeId.distance * schedule.routeId.costPerKm 
      : 5.00; // Default $5 if no cost specified

    // Format times for readability
    const formattedSchedule = {
      ...schedule.toObject(),
      formattedStartTime: schedule.startTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
      formattedEndTime: schedule.endTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
      fare: {
        baseFare: baseFare,
        currency: 'USD'
      }
    };

    res.status(200).json({
      status: true,
      data: formattedSchedule
    });
  } catch (error) {
    console.error('Error fetching schedule with fare:', error);
    res.status(500).json({
      status: false,
      message: 'Failed to fetch schedule with fare information',
      error: error.message
    });
  }
};

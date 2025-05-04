const { calculateDistanceAndTime } = require('./gpsUtils');
const mapsUtils = require('./mapsUtils');

/**
 * Calculate estimated arrival times for a schedule
 * @param {Object} schedule - Schedule object with stopTimes
 * @param {Object} vehicleLocation - Current location of the vehicle
 * @param {String} specificStopId - Optional specific stop ID to calculate for
 * @returns {Array} Array of stops with estimated arrival times
 */
exports.calculateEstimatedArrival = async (schedule, vehicleLocation = null, specificStopId = null) => {
  // If schedule has stop times, use those directly
  if (schedule.stopTimes && schedule.stopTimes.length > 0) {
    const stops = specificStopId 
      ? schedule.stopTimes.filter(stop => stop.stopId.toString() === specificStopId)
      : schedule.stopTimes;
      
    return stops.map(stop => ({
      stopId: stop.stopId,
      stopName: stop.stopName,
      estimatedArrival: stop.arrivalTime
    }));
  }
  
  // If no stop times are set, calculate based on route length and schedule duration
  try {
    await schedule.populate('routeId');
    const route = schedule.routeId;
    
    if (!route || !route.stops || route.stops.length === 0) {
      return [];
    }
    
    const totalDuration = (schedule.endTime - schedule.startTime) / 60000; // in minutes
    const stopsToProcess = specificStopId
      ? route.stops.filter(stop => stop._id.toString() === specificStopId)
      : route.stops;
      
    // Calculate estimated times based on even distribution
    const minutesPerStop = totalDuration / (route.stops.length - 1);
    
    return stopsToProcess.map((stop, index) => {
      const minutesOffset = index * minutesPerStop;
      const estimatedTime = new Date(schedule.startTime);
      estimatedTime.setMinutes(estimatedTime.getMinutes() + minutesOffset);
      
      return {
        stopId: stop._id,
        stopName: stop.name,
        estimatedArrival: estimatedTime
      };
    });
  } catch (error) {
    console.error('Error calculating arrival times:', error);
    return [];
  }
};

/**
 * Convert a time string to Date object
 * @param {String} timeString - Time string in HH:MM format
 * @param {Date} baseDate - Base date to use (defaults to today)
 * @returns {Date} Date object with the specified time
 */
exports.timeStringToDate = (timeString, baseDate = new Date()) => {
  const [hours, minutes] = timeString.split(':').map(Number);
  const date = new Date(baseDate);
  date.setHours(hours, minutes, 0, 0);
  return date;
};

/**
 * Format a date to time string (HH:MM)
 * @param {Date} date - Date object
 * @returns {String} Time string in HH:MM format
 */
exports.formatTimeString = (date) => {
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
};

/**
 * Calculate delay in minutes
 * @param {Date} scheduled - Scheduled time
 * @param {Date} actual - Actual time
 * @returns {Number} Delay in minutes (negative for early arrival)
 */
exports.calculateDelay = (scheduled, actual) => {
  return Math.round((actual - scheduled) / 60000);
};
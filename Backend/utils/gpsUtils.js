/**
 * Calculate distance between two points using the Haversine formula
 * @param {Array} point1 - [longitude, latitude] coordinates of point 1
 * @param {Array} point2 - [longitude, latitude] coordinates of point 2
 * @returns {Object} Object containing distance in meters and estimated travel time in seconds
 */
exports.calculateDistanceAndTime = (point1, point2) => {
  // Earth's radius in meters
  const radius = 6371000;
  
  // Convert coordinates from degrees to radians
  const lat1 = point1[1] * Math.PI / 180;
  const lat2 = point2[1] * Math.PI / 180;
  const lon1 = point1[0] * Math.PI / 180;
  const lon2 = point2[0] * Math.PI / 180;
  
  // Haversine formula
  const dLat = lat2 - lat1;
  const dLon = lon2 - lon1;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1) * Math.cos(lat2) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = radius * c; // distance in meters
  
  // Estimate travel time (assuming average speed of 30 km/h for urban areas)
  const averageSpeedMps = 30 * 1000 / 3600; // 30 km/h in meters per second
  const estimatedTime = distance / averageSpeedMps;
  
  return {
    distance,           // Distance in meters
    estimatedTime       // Estimated travel time in seconds
  };
};

/**
 * Check if a point is near a route
 * @param {Array} point - [longitude, latitude] coordinates
 * @param {Array} routePath - Array of [longitude, latitude] coordinates representing route path
 * @param {Number} maxDistance - Maximum distance in meters
 * @returns {Boolean} True if point is within maxDistance of any segment of the route
 */
exports.isPointNearRoute = (point, routePath, maxDistance = 100) => {
  // Initialize minimum distance as infinity
  let minDistance = Infinity;
  
  // Check each segment of the route
  for (let i = 0; i < routePath.length - 1; i++) {
    const segmentStart = routePath[i];
    const segmentEnd = routePath[i + 1];
    
    // Calculate distance from point to segment
    const distance = pointToLineDistance(point, segmentStart, segmentEnd);
    
    // Update minimum distance
    if (distance < minDistance) {
      minDistance = distance;
    }
    
    // Early return if we find a close enough segment
    if (minDistance <= maxDistance) {
      return true;
    }
  }
  
  return minDistance <= maxDistance;
};

/**
 * Calculate the minimum distance from a point to a line segment
 * @param {Array} point - [longitude, latitude] coordinates of the point
 * @param {Array} lineStart - [longitude, latitude] coordinates of segment start
 * @param {Array} lineEnd - [longitude, latitude] coordinates of segment end
 * @returns {Number} Distance in meters
 */
function pointToLineDistance(point, lineStart, lineEnd) {
  // Convert to Cartesian coordinates for simplification
  const x = point[0];
  const y = point[1];
  const x1 = lineStart[0];
  const y1 = lineStart[1];
  const x2 = lineEnd[0];
  const y2 = lineEnd[1];
  
  // Calculate line length squared
  const lenSq = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
  
  // If line is just a point, return distance to that point
  if (lenSq === 0) {
    return exports.calculateDistanceAndTime([x, y], [x1, y1]).distance;
  }
  
  // Calculate projection of point onto line
  const t = Math.max(0, Math.min(1, ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / lenSq));
  
  // Calculate nearest point on line segment
  const projX = x1 + t * (x2 - x1);
  const projY = y1 + t * (y2 - y1);
  
  // Return distance from point to nearest point on line segment
  return exports.calculateDistanceAndTime([x, y], [projX, projY]).distance;
}
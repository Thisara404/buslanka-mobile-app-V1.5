const jwt = require('jsonwebtoken');
require('dotenv').config();

// Verify JWT token middleware
const verifyToken = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ status: false, message: 'Access denied. No token provided.' });
  }

  try {
    console.log('Verifying token:', token.substring(0, 10) + '...');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Decoded token:', decoded);
    req.user = decoded;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({ status: false, message: 'Invalid token.' });
  }
};

// Role-based authentication middleware
const authorize = (roles = []) => {
  if (typeof roles === 'string') {
    roles = [roles];
  }

  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ status: false, message: 'User not authenticated' });
    }
    
    if (roles.length && !roles.includes(req.user.role)) {
      return res.status(403).json({ 
        status: false, 
        message: 'Unauthorized: You do not have permission to access this resource' 
      });
    }
    
    next();
  };
};

module.exports = {
  verifyToken,
  authorize
};
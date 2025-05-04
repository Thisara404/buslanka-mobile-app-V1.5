// Basic validation middleware for auth requests

const validateDriverRegistration = (req, res, next) => {
  const { name, phone, email, password, address, busDetails } = req.body;
  
  // Check required fields
  if (!name || !phone || !email || !password || !address) {
    return res.status(400).json({
      status: false,
      message: 'Please provide all required fields'
    });
  }
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid email address'
    });
  }
  
  // Validate phone number (simple validation)
  const phoneRegex = /^\d{10,15}$/;
  if (!phoneRegex.test(phone.replace(/[\s-]/g, ''))) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid phone number'
    });
  }
  
  // Validate password strength
  if (password.length < 6) {
    return res.status(400).json({
      status: false,
      message: 'Password must be at least 6 characters long'
    });
  }
  
  // Validate bus details
  if (!busDetails || !busDetails.busNumber) {
    return res.status(400).json({
      status: false,
      message: 'Bus number is required'
    });
  }
  
  next();
};

const validatePassengerRegistration = (req, res, next) => {
  const { name, phone, email, password, addresses } = req.body;
  
  // Check required fields
  if (!name || !phone || !email || !password) {
    return res.status(400).json({
      status: false,
      message: 'Please provide all required fields'
    });
  }
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid email address'
    });
  }
  
  // Validate phone number (simple validation)
  const phoneRegex = /^\d{10,15}$/;
  if (!phoneRegex.test(phone.replace(/[\s-]/g, ''))) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid phone number'
    });
  }
  
  // Validate password strength
  if (password.length < 6) {
    return res.status(400).json({
      status: false,
      message: 'Password must be at least 6 characters long'
    });
  }
  
  // Validate home address existence
  if (!addresses || !addresses.home) {
    return res.status(400).json({
      status: false,
      message: 'Home address is required'
    });
  }
  
  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({
      status: false,
      message: 'Email and password are required'
    });
  }
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid email address'
    });
  }
  
  next();
};

const validatePasswordReset = (req, res, next) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({
      status: false,
      message: 'Email is required'
    });
  }
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      status: false,
      message: 'Please provide a valid email address'
    });
  }
  
  next();
};

const validatePasswordUpdate = (req, res, next) => {
  const { token, password, confirmPassword } = req.body;
  
  if (!token || !password || !confirmPassword) {
    return res.status(400).json({
      status: false,
      message: 'All fields are required'
    });
  }
  
  if (password !== confirmPassword) {
    return res.status(400).json({
      status: false,
      message: 'Passwords do not match'
    });
  }
  
  if (password.length < 6) {
    return res.status(400).json({
      status: false,
      message: 'Password must be at least 6 characters long'
    });
  }
  
  next();
};

module.exports = {
  validateDriverRegistration,
  validatePassengerRegistration,
  validateLogin,
  validatePasswordReset,
  validatePasswordUpdate
};
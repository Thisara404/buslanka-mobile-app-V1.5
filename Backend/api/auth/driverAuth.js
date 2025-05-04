const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Driver = require('../../model/Driver');
const { validateDriverRegistration, validateLogin, validatePasswordReset, validatePasswordUpdate } = require('../../middleware/validation');
const { verifyToken } = require('../../middleware/auth');

// Store password reset tokens (in production, use Redis or a database)
const passwordResetTokens = {};

// Driver Registration
router.post('/register', validateDriverRegistration, async (req, res) => {
  try {
    const { name, phone, email, password, address, busDetails, image } = req.body;

    // Check if driver already exists
    const existingDriver = await Driver.findOne({ 
      $or: [{ email }, { phone }, { 'busDetails.busNumber': busDetails?.busNumber }] 
    });

    if (existingDriver) {
      if (existingDriver.email === email) {
        return res.status(400).json({ status: false, message: 'Email already in use' });
      }
      if (existingDriver.phone === phone) {
        return res.status(400).json({ status: false, message: 'Phone number already in use' });
      }
      if (existingDriver.busDetails?.busNumber === busDetails?.busNumber) {
        return res.status(400).json({ status: false, message: 'Bus number already in use' });
      }
    }

    // Create new driver
    const newDriver = new Driver({
      name,
      phone,
      email,
      password,
      address,
      busDetails,
      image
    });

    await newDriver.save();

    res.status(201).json({
      status: true,
      message: 'Driver registered successfully',
      data: {
        _id: newDriver._id,
        name: newDriver.name,
        email: newDriver.email
      }
    });
  } catch (error) {
    console.error('Driver registration error:', error);
    res.status(500).json({ status: false, message: 'Registration failed', error: error.message });
  }
});

// Driver Login
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find driver
    const driver = await Driver.findOne({ email });
    if (!driver) {
      return res.status(401).json({ status: false, message: 'Invalid email or password' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(password, driver.password);
    if (!validPassword) {
      return res.status(401).json({ status: false, message: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: driver._id, role: 'driver' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      status: true,
      message: 'Login successful',
      token,
      data: {
        _id: driver._id,
        name: driver.name,
        email: driver.email,
        role: 'driver'
      }
    });
  } catch (error) {
    console.error('Driver login error:', error);
    res.status(500).json({ status: false, message: 'Login failed', error: error.message });
  }
});

// Request Password Reset
router.post('/forgot-password', validatePasswordReset, async (req, res) => {
  try {
    const { email } = req.body;
    
    // Check if driver exists
    const driver = await Driver.findOne({ email });
    if (!driver) {
      return res.status(404).json({ 
        status: false, 
        message: 'No account with this email exists' 
      });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const tokenExpiry = Date.now() + 3600000; // 1 hour validity
    
    passwordResetTokens[resetToken] = {
      email,
      timestamp: Date.now()
    };

    // Setup for email notification
    const resetLink = `${process.env.FRONTEND_URL || 'http://192.168.43.187:3001'}/reset-password?token=${resetToken}`;
    
    // In production, send email with reset link
    // Example: await sendEmail(email, 'Password Reset', `Click to reset your password: ${resetLink}`);
    
    console.log(`Password reset requested for ${email}. Reset link: ${resetLink}`);

    res.status(200).json({
      status: true,
      message: 'Password reset link sent to your email',
      resetToken // Remove this in production
    });
  } catch (error) {
    console.error('Password reset request error:', error);
    res.status(500).json({ 
      status: false, 
      message: 'Failed to process password reset request', 
      error: error.message 
    });
  }
});

// Reset Password
router.post('/reset-password', validatePasswordUpdate, async (req, res) => {
  try {
    const { token, password } = req.body;
    
    // Verify token
    const resetData = passwordResetTokens[token];
    if (!resetData) {
      return res.status(400).json({ status: false, message: 'Invalid or expired token' });
    }

    // Check if token is expired (1 hour validity)
    if (Date.now() - resetData.timestamp > 3600000) {
      delete passwordResetTokens[token];
      return res.status(400).json({ status: false, message: 'Token has expired' });
    }

    // Find driver and update password
    const driver = await Driver.findOne({ email: resetData.email });
    if (!driver) {
      return res.status(404).json({ status: false, message: 'Driver not found' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    driver.password = await bcrypt.hash(password, salt);
    await driver.save();

    // Remove used token
    delete passwordResetTokens[token];

    res.status(200).json({
      status: true,
      message: 'Password reset successful'
    });
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ status: false, message: 'Failed to reset password', error: error.message });
  }
});

// Validate Token
router.get('/validate-token', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ status: false, message: 'Unauthorized' });
    }
    
    // Get driver data
    const driver = await Driver.findById(req.user.id).select('-password');
    if (!driver) {
      return res.status(404).json({ status: false, message: 'Driver not found' });
    }

    res.status(200).json({
      status: true,
      message: 'Token is valid',
      data: {
        driver,
        role: 'driver'
      }
    });
  } catch (error) {
    console.error('Token validation error:', error);
    res.status(500).json({ status: false, message: 'Failed to validate token', error: error.message });
  }
});

// _buildInfoRow('Bus Number', _driverData['busDetails']['busNumber']),
// _buildInfoRow('Model', _driverData['busDetails']['busModel']),
// _buildInfoRow('Color', _driverData['busDetails']['busColor']),

module.exports = router;
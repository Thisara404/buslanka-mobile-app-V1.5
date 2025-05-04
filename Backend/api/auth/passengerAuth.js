const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Passenger = require('../../model/Passenger');
const { validatePassengerRegistration, validateLogin, validatePasswordReset, validatePasswordUpdate } = require('../../middleware/validation');
const { verifyToken } = require('../../middleware/auth');

// Store password reset tokens (in production, use Redis or a database)
const passwordResetTokens = {};

// Passenger Registration
router.post('/register', validatePassengerRegistration, async (req, res) => {
  try {
    const { name, phone, email, password, addresses, image } = req.body;

    // Check if passenger already exists
    const existingPassenger = await Passenger.findOne({ 
      $or: [{ email }, { phone }] 
    });

    if (existingPassenger) {
      if (existingPassenger.email === email) {
        return res.status(400).json({ status: false, message: 'Email already in use' });
      }
      if (existingPassenger.phone === phone) {
        return res.status(400).json({ status: false, message: 'Phone number already in use' });
      }
    }

    // Create new passenger
    const newPassenger = new Passenger({
      name,
      phone,
      email,
      password,
      addresses,
      image
    });

    await newPassenger.save();

    res.status(201).json({
      status: true,
      message: 'Passenger registered successfully',
      data: {
        _id: newPassenger._id,
        name: newPassenger.name,
        email: newPassenger.email
      }
    });
  } catch (error) {
    console.error('Passenger registration error:', error);
    res.status(500).json({ status: false, message: 'Registration failed', error: error.message });
  }
});

// Passenger Login
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find passenger
    const passenger = await Passenger.findOne({ email });
    if (!passenger) {
      return res.status(401).json({ status: false, message: 'Invalid email or password' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(password, passenger.password);
    if (!validPassword) {
      return res.status(401).json({ status: false, message: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: passenger._id, role: 'passenger' },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(200).json({
      status: true,
      message: 'Login successful',
      token,
      data: {
        _id: passenger._id,
        name: passenger.name,
        email: passenger.email,
        role: 'passenger'
      }
    });
  } catch (error) {
    console.error('Passenger login error:', error);
    res.status(500).json({ status: false, message: 'Login failed', error: error.message });
  }
});

// Request Password Reset
router.post('/forgot-password', validatePasswordReset, async (req, res) => {
  try {
    const { email } = req.body;
    
    // Check if passenger exists
    const passenger = await Passenger.findOne({ email });
    if (!passenger) {
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
    const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/reset-password?token=${resetToken}&role=passenger`;
    
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

    // Find passenger and update password
    const passenger = await Passenger.findOne({ email: resetData.email });
    if (!passenger) {
      return res.status(404).json({ status: false, message: 'Passenger not found' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    passenger.password = await bcrypt.hash(password, salt);
    await passenger.save();

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
    if (req.user.role !== 'passenger') {
      return res.status(403).json({ status: false, message: 'Unauthorized' });
    }
    
    // Get passenger data
    const passenger = await Passenger.findById(req.user.id).select('-password');
    if (!passenger) {
      return res.status(404).json({ status: false, message: 'Passenger not found' });
    }

    res.status(200).json({
      status: true,
      message: 'Token is valid',
      data: {
        passenger,
        role: 'passenger'
      }
    });
  } catch (error) {
    console.error('Token validation error:', error);
    res.status(500).json({ status: false, message: 'Failed to validate token', error: error.message });
  }
});

module.exports = router;
const express = require('express');
const { verifyToken } = require('../middleware/auth');
const paymentController = require('../controllers/payment.controller');

const router = express.Router();

// Protected routes
router.use(verifyToken);

// Payment creation and capture routes
router.post('/create-order', paymentController.createPaymentOrder);
router.post('/capture/:orderId', paymentController.capturePayment);

// Get payment history
router.get('/history', paymentController.getPaymentHistory);

// Get payment details
router.get('/:paymentId', paymentController.getPaymentDetails);

// Process refund
router.post('/:paymentId/refund', paymentController.processRefund);

module.exports = router;
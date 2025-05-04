const PaymentService = require('../services/payment.services');
const Payment = require('../model/Payment');

exports.createPaymentOrder = async (req, res) => {
    try {
        const { journeyId, amount } = req.body;
        const passengerId = req.user.id; // Assuming auth middleware sets this

        const metadata = {
            ipAddress: req.ip,
            userAgent: req.headers['user-agent'],
            requestId: req.headers['x-request-id']
        };

        const order = await PaymentService.createPaymentOrder(journeyId, passengerId, amount, metadata);

        if (!order.success) {
            return res.status(400).json({
                status: false,
                message: order.error
            });
        }

        res.status(200).json({
            status: true,
            data: order.data
        });
    } catch (error) {
        console.error('Payment order creation error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to create payment order',
            error: error.message
        });
    }
};

exports.capturePayment = async (req, res) => {
    try {
        const { orderId } = req.params;

        const result = await PaymentService.capturePayment(orderId);

        if (!result.success) {
            return res.status(400).json({
                status: false,
                message: result.error,
                details: result.details
            });
        }

        res.status(200).json({
            status: true,
            data: result.data
        });
    } catch (error) {
        console.error('Payment capture error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to capture payment',
            error: error.message
        });
    }
};

exports.getPaymentDetails = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const result = await PaymentService.getPaymentDetails(paymentId);

        if (!result.success) {
            return res.status(404).json({
                status: false,
                message: result.error
            });
        }

        res.status(200).json({
            status: true,
            data: result.data
        });
    } catch (error) {
        console.error('Get payment details error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to get payment details',
            error: error.message
        });
    }
};

exports.getPaymentHistory = async (req, res) => {
    try {
        const passengerId = req.user.id; // Assuming auth middleware sets this
        const { page = 1, limit = 10 } = req.query;
        
        const result = await PaymentService.getPaymentHistory(
            passengerId,
            parseInt(page),
            parseInt(limit)
        );

        res.status(200).json({
            status: true,
            data: result
        });
    } catch (error) {
        console.error('Get payment history error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to get payment history',
            error: error.message
        });
    }
};

exports.processRefund = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const { reason } = req.body;

        const result = await PaymentService.processRefund(paymentId, reason);

        if (!result.success) {
            return res.status(400).json({
                status: false,
                message: result.error
            });
        }

        res.status(200).json({
            status: true,
            data: result.data
        });
    } catch (error) {
        console.error('Refund processing error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to process refund',
            error: error.message
        });
    }
};
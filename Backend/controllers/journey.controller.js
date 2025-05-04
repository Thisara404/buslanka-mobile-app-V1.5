const JourneyService = require('../services/journey.services');
const PaymentService = require('../services/payment.services');

exports.bookJourney = async (req, res) => {
    try {
        const { scheduleId, paymentMethod } = req.body;
        const passengerId = req.user.id; // From auth middleware

        if (!scheduleId) {
            return res.status(400).json({
                status: false,
                message: 'Schedule ID is required'
            });
        }

        const result = await JourneyService.bookJourney(
            passengerId, 
            scheduleId, 
            paymentMethod || 'online'
        );

        if (!result.success) {
            return res.status(400).json({
                status: false,
                message: result.error
            });
        }

        res.status(201).json({
            status: true,
            message: 'Journey booked successfully',
            data: result.data
        });
    } catch (error) {
        console.error('Journey booking error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to book journey',
            error: error.message
        });
    }
};

exports.getPassengerJourneys = async (req, res) => {
    try {
        const passengerId = req.user.id; // From auth middleware
        const { status, page = 1, limit = 10 } = req.query;

        const result = await JourneyService.getPassengerJourneys(
            passengerId,
            status,
            parseInt(page),
            parseInt(limit)
        );

        res.status(200).json({
            status: true,
            data: result
        });
    } catch (error) {
        console.error('Get passenger journeys error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to get journeys',
            error: error.message
        });
    }
};

exports.getJourneyDetails = async (req, res) => {
    try {
        const { journeyId } = req.params;
        const userId = req.user.id; // From auth middleware
        const userRole = req.user.role;

        const result = await JourneyService.getJourneyDetails(journeyId);

        if (!result.success) {
            return res.status(404).json({
                status: false,
                message: result.error
            });
        }

        // Check authorization
        if (userRole !== 'admin' && 
            userRole !== 'driver' &&
            result.data.passengerId._id.toString() !== userId) {
            return res.status(403).json({
                status: false,
                message: 'Unauthorized to view this journey'
            });
        }

        res.status(200).json({
            status: true,
            data: result.data
        });
    } catch (error) {
        console.error('Get journey details error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to get journey details',
            error: error.message
        });
    }
};

exports.cancelJourney = async (req, res) => {
    try {
        const { journeyId } = req.params;
        const passengerId = req.user.id; // From auth middleware

        const result = await JourneyService.cancelJourney(journeyId, passengerId);

        if (!result.success) {
            return res.status(400).json({
                status: false,
                message: result.error
            });
        }

        res.status(200).json({
            status: true,
            message: 'Journey cancelled successfully',
            data: result.data
        });
    } catch (error) {
        console.error('Journey cancellation error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to cancel journey',
            error: error.message
        });
    }
};

exports.verifyJourney = async (req, res) => {
    try {
        const { journeyId } = req.params;
        const driverId = req.user.id; // From auth middleware
        
        // Ensure user is a driver
        if (req.user.role !== 'driver') {
            return res.status(403).json({
                status: false,
                message: 'Only drivers can verify journeys'
            });
        }

        const result = await JourneyService.verifyJourney(journeyId, driverId);

        if (!result.success) {
            return res.status(400).json({
                status: false,
                message: result.error
            });
        }

        res.status(200).json({
            status: true,
            message: 'Journey verified successfully',
            data: result.data
        });
    } catch (error) {
        console.error('Journey verification error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to verify journey',
            error: error.message
        });
    }
};

exports.initiatePayment = async (req, res) => {
    try {
        const { journeyId } = req.params;
        const passengerId = req.user.id; // From auth middleware

        // Get journey to verify fare
        const journeyResult = await JourneyService.getJourneyDetails(journeyId);
        if (!journeyResult.success) {
            return res.status(404).json({
                status: false,
                message: journeyResult.error
            });
        }

        // Verify journey belongs to this passenger
        if (journeyResult.data.passengerId._id.toString() !== passengerId) {
            return res.status(403).json({
                status: false,
                message: 'Unauthorized: Journey does not belong to this passenger'
            });
        }

        // Get the fare from the journey
        const amount = journeyResult.data.fare;

        const metadata = {
            ipAddress: req.ip,
            userAgent: req.headers['user-agent'],
            requestId: req.headers['x-request-id']
        };

        // Create payment order
        const paymentResult = await PaymentService.createPaymentOrder(
            journeyId,
            passengerId,
            amount,
            metadata
        );

        if (!paymentResult.success) {
            return res.status(400).json({
                status: false,
                message: paymentResult.error
            });
        }

        res.status(200).json({
            status: true,
            message: 'Payment initiated successfully',
            data: paymentResult.data
        });
    } catch (error) {
        console.error('Payment initiation error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to initiate payment',
            error: error.message
        });
    }
};
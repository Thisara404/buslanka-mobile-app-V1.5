const Schedule = require('../model/Schedule');
const Route = require('../model/Route');
const PaymentService = require('../services/payment.services');
const JourneyService = require('../services/journey.services');
const mongoose = require('mongoose');
const qrcode = require('qrcode');

// Get fare calculation for a schedule
exports.getScheduleFare = async (req, res) => {
    try {
        const { scheduleId } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(scheduleId)) {
            return res.status(400).json({
                status: false,
                message: 'Invalid schedule ID format'
            });
        }

        // Get schedule details
        const schedule = await Schedule.findById(scheduleId).populate('routeId');
        if (!schedule) {
            return res.status(404).json({
                status: false,
                message: 'Schedule not found'
            });
        }

        // Get route details for fare calculation
        const route = await Route.findById(schedule.routeId);
        if (!route) {
            return res.status(404).json({
                status: false,
                message: 'Route not found'
            });
        }

        // Calculate base fare - could be from route or fixed amount
        const baseFare = route.costPerKm ? route.distance * route.costPerKm : 5.00;

        res.status(200).json({
            status: true,
            data: {
                scheduleId: schedule._id,
                routeName: route.name,
                baseFare: baseFare,
                currency: 'USD'
            }
        });
    } catch (error) {
        console.error('Error calculating fare:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to calculate fare',
            error: error.message
        });
    }
};

// Create payment for schedule with multiple passengers
exports.createSchedulePayment = async (req, res) => {
    try {
        const { scheduleId } = req.params;
        const { passengerCount, additionalPassengers } = req.body;
        const passengerId = req.user.id; // From auth middleware

        if (!mongoose.Types.ObjectId.isValid(scheduleId)) {
            return res.status(400).json({
                status: false,
                message: 'Invalid schedule ID format'
            });
        }

        // Validate passenger count
        const count = parseInt(passengerCount) || 1;
        if (count < 1 || count > 10) { // Setting reasonable limits
            return res.status(400).json({
                status: false,
                message: 'Passenger count must be between 1 and 10'
            });
        }

        // Get schedule and calculate fare
        const schedule = await Schedule.findById(scheduleId).populate('routeId');
        if (!schedule) {
            return res.status(404).json({
                status: false,
                message: 'Schedule not found'
            });
        }

        const route = await Route.findById(schedule.routeId);
        const baseFare = route.costPerKm ? route.distance * route.costPerKm : 5.00;
        const totalAmount = baseFare * count;

        // Create a journey for the main passenger
        const mainJourney = await JourneyService.bookJourney(
            passengerId,
            scheduleId,
            'online'
        );

        if (!mainJourney.success) {
            return res.status(400).json({
                status: false,
                message: mainJourney.error
            });
        }

        // Store all journeys
        const journeys = [mainJourney.data._id];
        
        // Process additional passengers if provided
        if (additionalPassengers && Array.isArray(additionalPassengers) && count > 1) {
            // Handle additional passenger information
            for (let i = 0; i < Math.min(additionalPassengers.length, count - 1); i++) {
                const additionalPassenger = additionalPassengers[i];
                
                // You could create these as anonymous journeys linked to the main passenger
                // Or store additional passenger details if provided
                const additionalJourney = await JourneyService.bookJourney(
                    passengerId, // Still using the main passenger's ID
                    scheduleId,
                    'online',
                    additionalPassenger // Pass additional passenger info to JourneyService
                );
                
                if (additionalJourney.success) {
                    journeys.push(additionalJourney.data._id);
                }
            }
        }

        // Create metadata for payment
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.headers['user-agent'],
            requestId: req.headers['x-request-id'],
            passengerCount: count,
            journeys: journeys
        };

        // Create payment order with the main journey
        const paymentResult = await PaymentService.createSchedulePayment(
            mainJourney.data._id,
            passengerId,
            totalAmount,
            journeys.slice(1), // Additional journeys (exclude main journey)
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
            data: {
                ...paymentResult.data,
                passengerCount: count,
                totalAmount
            }
        });
    } catch (error) {
        console.error('Error creating schedule payment:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to create payment',
            error: error.message
        });
    }
};

// Get payment details for a schedule
exports.getSchedulePaymentDetails = async (req, res) => {
    try {
        const { scheduleId } = req.params;
        const passengerId = req.user.id;

        if (!mongoose.Types.ObjectId.isValid(scheduleId)) {
            return res.status(400).json({
                status: false,
                message: 'Invalid schedule ID format'
            });
        }

        // Find payments for this schedule and passenger
        const payments = await Payment.find({
            'journeyId.scheduleId': scheduleId,
            passengerId: passengerId
        })
        .populate({
            path: 'journeyId',
            populate: {
                path: 'scheduleId',
                select: 'routeId startTime endTime'
            }
        })
        .populate('additionalJourneys')
        .sort({ createdAt: -1 });

        if (!payments || payments.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'No payments found for this schedule'
            });
        }

        res.status(200).json({
            status: true,
            data: payments
        });
    } catch (error) {
        console.error('Error retrieving schedule payments:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to retrieve schedule payments',
            error: error.message
        });
    }
};
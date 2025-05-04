const PayPal = require('@paypal/checkout-server-sdk');
const { client } = require('../config/paypal');
const Payment = require('../model/Payment');
const Journey = require('../model/Journey');
const Passenger = require('../model/Passenger');
const JourneyService = require('./journey.services');
const logger = require('../utils/logger');

class PaymentService {
    async createPaymentOrder(journeyId, passengerId, amount, metadata = {}) {
        try {
            const journey = await Journey.findById(journeyId)
                .populate('driverId', 'name');
            
            const passenger = await Passenger.findById(passengerId);

            if (!journey) {
                logger.error(`Journey not found: ${journeyId}`);
                throw new Error('Journey not found');
            }

            if (!passenger) {
                logger.error(`Passenger not found: ${passengerId}`);
                throw new Error('Passenger not found');
            }

            // Verify journey belongs to this passenger
            if (journey.passengerId.toString() !== passengerId) {
                logger.error(`Unauthorized: Journey does not belong to passenger ${passengerId}`);
                throw new Error('Unauthorized: Journey does not belong to this passenger');
            }

            // Create PayPal order
            const request = new PayPal.orders.OrdersCreateRequest();
            request.prefer("return=representation");
            request.requestBody({
                intent: 'CAPTURE',
                purchase_units: [{
                    amount: {
                        currency_code: 'USD',
                        value: amount.toString()
                    },
                    description: `Bus Journey payment for route ${journey.routeDetails ? journey.routeDetails.routeName : 'unknown'}`
                }]
            });

            // Call PayPal to create the order
            const order = await client.execute(request);

            // Create payment record
            const payment = await Payment.create({
                journeyId,
                passengerId,
                amount,
                paypalOrderId: order.result.id,
                status: 'PENDING',
                metadata: {
                    ...metadata,
                    requestId: order.result.id,
                    attemptCount: 1,
                    ipAddress: metadata.ipAddress || '',
                    userAgent: metadata.userAgent || ''
                }
            });

            logger.info(`Payment order created: ${payment._id}`);

            return {
                success: true,
                data: {
                    paymentId: payment._id,
                    orderId: order.result.id,
                    status: order.result.status,
                    links: order.result.links
                }
            };
        } catch (error) {
            logger.error(`Payment order creation failed: ${error.message}`);
            return {
                success: false,
                error: error.message || 'Payment order creation failed'
            };
        }
    }

    async createSchedulePayment(journeyId, passengerId, amount, additionalJourneyIds = [], metadata = {}) {
        try {
            const journey = await Journey.findById(journeyId)
                .populate({
                    path: 'scheduleId',
                    populate: {
                        path: 'routeId'
                    }
                })
                .populate('driverId', 'name');
            
            const passenger = await Passenger.findById(passengerId);

            if (!journey) {
                logger.error(`Journey not found: ${journeyId}`);
                throw new Error('Journey not found');
            }

            if (!passenger) {
                logger.error(`Passenger not found: ${passengerId}`);
                throw new Error('Passenger not found');
            }

            // Verify journey belongs to this passenger
            if (journey.passengerId.toString() !== passengerId) {
                logger.error(`Unauthorized: Journey does not belong to passenger ${passengerId}`);
                throw new Error('Unauthorized: Journey does not belong to this passenger');
            }

            // Create PayPal order
            const request = new PayPal.orders.OrdersCreateRequest();
            request.prefer("return=representation");
            
            // Get route name from the journey
            const routeName = journey.scheduleId && journey.scheduleId.routeId ? 
                journey.scheduleId.routeId.name : 'unknown';
            
            // Format description to include passenger count
            const passengerCount = metadata.passengerCount || 1;
            const description = `Bus Ticket payment - ${passengerCount} passenger${passengerCount > 1 ? 's' : ''} for route ${routeName}`;
            
            request.requestBody({
                intent: 'CAPTURE',
                purchase_units: [{
                    amount: {
                        currency_code: 'USD',
                        value: amount.toString()
                    },
                    description: description
                }],
                application_context: {
                    return_url: `${process.env.CLIENT_URL}/payment/success`,
                    cancel_url: `${process.env.CLIENT_URL}/payment/cancel`
                }
            });

            // Call PayPal to create the order
            const order = await client.execute(request);

            // Create payment record
            const payment = await Payment.create({
                journeyId,
                additionalJourneys: additionalJourneyIds,
                passengerCount: passengerCount,
                passengerId,
                amount,
                paypalOrderId: order.result.id,
                status: 'PENDING',
                metadata: {
                    ...metadata,
                    requestId: order.result.id,
                    attemptCount: 1,
                    ipAddress: metadata.ipAddress || '',
                    userAgent: metadata.userAgent || '',
                    passengerCount: passengerCount,
                    journeys: [journeyId, ...additionalJourneyIds]
                }
            });

            logger.info(`Multi-passenger payment order created: ${payment._id} for ${passengerCount} passengers`);

            return {
                success: true,
                data: {
                    paymentId: payment._id,
                    orderId: order.result.id,
                    status: order.result.status,
                    links: order.result.links
                }
            };
        } catch (error) {
            logger.error(`Schedule payment creation failed: ${error.message}`);
            return {
                success: false,
                error: error.message || 'Payment order creation failed'
            };
        }
    }

    async capturePayment(orderId) {
        try {
            // Validate order ID
            if (!orderId) {
                throw new Error('Order ID is required');
            }

            logger.info(`Attempting to capture payment for order: ${orderId}`);

            // Find the payment record
            const payment = await Payment.findOne({ paypalOrderId: orderId });
            if (!payment) {
                logger.error(`Payment record not found for order: ${orderId}`);
                throw new Error('Payment record not found');
            }

            try {
                // Create capture request
                const request = new PayPal.orders.OrdersCaptureRequest(orderId);
                request.prefer("return=representation");
                request.requestBody({}); // Empty request body for capture

                // Execute the capture request
                const capture = await client.execute(request);

                if (capture.result.status === 'COMPLETED') {
                    // Update payment record
                    payment.status = 'COMPLETED';
                    payment.transactionDetails = {
                        captureId: capture.result.purchase_units[0].payments.captures[0].id,
                        paymentMethod: 'PayPal',
                        captureStatus: capture.result.status,
                        captureTime: new Date(),
                        paypalResponse: capture.result
                    };
                    await payment.save();

                    // Update journey payment status for primary and additional journeys
                    let journeyUpdate;
                    
                    if (payment.additionalJourneys && payment.additionalJourneys.length > 0) {
                        // Update all journeys
                        const allJourneyIds = [payment.journeyId, ...payment.additionalJourneys];
                        journeyUpdate = await JourneyService.updateMultipleJourneyPaymentStatus(
                            allJourneyIds, 'paid'
                        );
                    } else {
                        // Update just the main journey
                        journeyUpdate = await JourneyService.updateJourneyPaymentStatus(
                            payment.journeyId, 'paid'
                        );
                    }

                    if (!journeyUpdate.success) {
                        logger.error(`Failed to update journey payment status: ${journeyUpdate.error}`);
                    }

                    logger.info(`Payment captured successfully: ${orderId} for ${payment.passengerCount} passengers`);

                    return {
                        success: true,
                        data: {
                            paymentId: payment._id,
                            status: 'COMPLETED',
                            captureId: capture.result.purchase_units[0].payments.captures[0].id,
                            amount: capture.result.purchase_units[0].payments.captures[0].amount,
                            journey: journeyUpdate.success ? journeyUpdate.data : null,
                            passengerCount: payment.passengerCount || 1
                        }
                    };
                } else {
                    throw new Error(`Capture failed with status: ${capture.result.status}`);
                }
            } catch (paypalError) {
                logger.error(`PayPal capture error: ${paypalError.message}`);
                throw new Error(`PayPal capture failed: ${paypalError.message}`);
            }
        } catch (error) {
            logger.error(`Payment capture failed: ${error.message}`);
            return {
                success: false,
                error: error.message || 'Payment capture failed',
                details: error.details || []
            };
        }
    }

    async getPaymentDetails(paymentId) {
        try {
            const payment = await Payment.findById(paymentId)
                .populate('journeyId')
                .populate('passengerId');

            if (!payment) {
                throw new Error('Payment not found');
            }

            return {
                success: true,
                data: payment
            };
        } catch (error) {
            logger.error(`Get payment details failed: ${error.message}`);
            throw new Error(error.message);
        }
    }

    async getPaymentHistory(passengerId, page = 1, limit = 10) {
        try {
            const query = { passengerId };
            
            const skip = (page - 1) * limit;
            const payments = await Payment.find(query)
                .populate('journeyId')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit);

            const total = await Payment.countDocuments(query);

            return {
                payments,
                pagination: {
                    current: page,
                    total: Math.ceil(total / limit),
                    totalRecords: total
                }
            };
        } catch (error) {
            logger.error(`Failed to get payment history: ${error.message}`);
            throw new Error('Failed to retrieve payment history');
        }
    }

    async processRefund(paymentId, reason) {
        let payment;
        
        try {
            // Find payment
            payment = await Payment.findById(paymentId).populate('journeyId passengerId');
            
            if (!payment) {
                throw new Error('Payment not found');
            }

            if (payment.status === 'REFUNDED') {
                throw new Error('Payment has already been refunded');
            }

            // Create PayPal refund request
            const request = new PayPal.payments.CapturesRefundRequest(payment.transactionDetails.captureId);
            request.requestBody({
                amount: {
                    currency_code: payment.currency || 'USD',
                    value: payment.amount.toString()
                },
                note_to_payer: `Refund for journey: ${reason}`
            });

            logger.info(`Processing refund for payment ${payment._id}`);

            // Process the refund
            const refund = await client.execute(request);

            // Update payment status
            payment.status = 'REFUNDED';
            payment.refundDetails = {
                refundId: refund.result.id,
                reason: reason,
                refundedAt: new Date(),
                status: 'COMPLETED',
                amount: payment.amount
            };
            await payment.save();

            // Update journey payment status
            const journeyUpdate = await JourneyService.updateJourneyPaymentStatus(
                payment.journeyId, 'refunded'
            );

            if (!journeyUpdate.success) {
                logger.error(`Failed to update journey payment status for refund: ${journeyUpdate.error}`);
            }

            logger.info(`Refund processed successfully: ${refund.result.id}`);

            return {
                success: true,
                data: {
                    refundId: refund.result.id,
                    status: 'REFUNDED',
                    amount: payment.amount,
                    currency: payment.currency || 'USD'
                }
            };
        } catch (error) {
            logger.error(`Refund processing failed: ${error.message}`);
            
            if (payment) {
                payment.status = 'REFUND_FAILED';
                await payment.save();
            }
            
            throw new Error(error.message || 'Refund processing failed');
        }
    }
}

module.exports = new PaymentService();
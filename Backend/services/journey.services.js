const Journey = require('../model/Journey');
const Schedule = require('../model/Schedule');
const Route = require('../model/Route');
const logger = require('../utils/logger');
const qrcode = require('qrcode');
const crypto = require('crypto');

class JourneyService {
    
    async bookJourney(passengerId, scheduleId, paymentMethod = 'online', additionalPassengerInfo = null) {
        try {
            // Validate schedule existence
            const schedule = await Schedule.findById(scheduleId).populate('routeId');
            if (!schedule) {
                throw new Error('Schedule not found');
            }
            
            // Get route details
            const route = await Route.findById(schedule.routeId);
            if (!route) {
                throw new Error('Route not found');
            }
            
            // Calculate fare - in a real app, this might be more complex
            // based on distance, passenger type, etc.
            const fare = route.costPerKm ? route.distance * route.costPerKm : 5.00;
            
            // Create journey object
            const journey = new Journey({
                scheduleId,
                passengerId,
                driverId: schedule.driverId,
                routeDetails: {
                    routeId: route._id,
                    routeName: route.name,
                    startLocation: route.stops[0] ? {
                        name: route.stops[0].name,
                        coordinates: route.stops[0].location.coordinates
                    } : null,
                    endLocation: route.stops[route.stops.length - 1] ? {
                        name: route.stops[route.stops.length - 1].name,
                        coordinates: route.stops[route.stops.length - 1].location.coordinates
                    } : null
                },
                startTime: schedule.startTime,
                endTime: schedule.endTime,
                status: 'booked',
                paymentStatus: paymentMethod === 'in-bus' ? 'pending' : 'pending',
                paymentMethod,
                fare
            });
            
            // Add additional passenger info if provided
            if (additionalPassengerInfo) {
                journey.additionalPassengerInfo = additionalPassengerInfo;
                journey.isAdditionalPassenger = true;
            }
            
            // Generate QR code data
            const qrData = JSON.stringify({
                journeyId: journey._id,
                passengerId,
                scheduleId,
                timestamp: new Date().toISOString(),
                hash: crypto.createHash('sha256')
                    .update(`${journey._id}${passengerId}${scheduleId}${process.env.JWT_SECRET || 'bus-ticket-secret'}`)
                    .digest('hex')
            });
            
            // Generate QR code
            const qrCodeImage = await qrcode.toDataURL(qrData);
            journey.qrCode = qrCodeImage;
            
            // Save journey
            await journey.save();
            
            logger.info(`Journey booked: ${journey._id} by passenger: ${passengerId}`);
            
            return {
                success: true,
                data: journey
            };
        } catch (error) {
            logger.error(`Journey booking failed: ${error.message}`);
            return {
                success: false,
                error: error.message || 'Failed to book journey'
            };
        }
    }
    
    async getPassengerJourneys(passengerId, status = null, page = 1, limit = 10) {
        try {
            const query = { passengerId };
            
            if (status) {
                query.status = status;
            }
            
            const skip = (page - 1) * limit;
            const journeys = await Journey.find(query)
                .populate('scheduleId', 'dayOfWeek startTime endTime status')
                .sort({ startTime: -1 })
                .skip(skip)
                .limit(limit);
                
            const total = await Journey.countDocuments(query);
            
            return {
                journeys,
                pagination: {
                    current: page,
                    total: Math.ceil(total / limit),
                    totalRecords: total
                }
            };
        } catch (error) {
            logger.error(`Failed to get passenger journeys: ${error.message}`);
            throw new Error('Failed to retrieve journeys');
        }
    }
    
    async getJourneyDetails(journeyId) {
        try {
            const journey = await Journey.findById(journeyId)
                .populate('scheduleId')
                .populate('passengerId', 'name email phone')
                .populate('driverId', 'name phone');
                
            if (!journey) {
                throw new Error('Journey not found');
            }
            
            return {
                success: true,
                data: journey
            };
        } catch (error) {
            logger.error(`Get journey details failed: ${error.message}`);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    async verifyJourney(journeyId, driverId) {
        try {
            const journey = await Journey.findById(journeyId);
            
            if (!journey) {
                throw new Error('Journey not found');
            }
            
            if (journey.isVerified) {
                throw new Error('Journey already verified');
            }
            
            // Update journey status
            journey.isVerified = true;
            journey.verifiedBy = driverId;
            journey.verifiedAt = new Date();
            
            if (journey.paymentMethod === 'in-bus' && journey.paymentStatus === 'pending') {
                journey.paymentStatus = 'paid';
            }
            
            await journey.save();
            
            logger.info(`Journey verified: ${journey._id} by driver: ${driverId}`);
            
            return {
                success: true,
                data: journey
            };
        } catch (error) {
            logger.error(`Journey verification failed: ${error.message}`);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    async cancelJourney(journeyId, passengerId) {
        try {
            const journey = await Journey.findOne({ 
                _id: journeyId, 
                passengerId 
            });
            
            if (!journey) {
                throw new Error('Journey not found or unauthorized');
            }
            
            // Only allow cancellation for booked journeys
            if (journey.status !== 'booked') {
                throw new Error(`Cannot cancel journey in ${journey.status} status`);
            }
            
            // Update journey status
            journey.status = 'cancelled';
            await journey.save();
            
            // If payment was made, initiate refund process
            if (journey.paymentStatus === 'paid' && journey.paymentMethod === 'online') {
                // Find the payment and initiate refund - this is handled in payment service
                // We'll implement this in the next step
            }
            
            logger.info(`Journey cancelled: ${journey._id} by passenger: ${passengerId}`);
            
            return {
                success: true,
                data: journey
            };
        } catch (error) {
            logger.error(`Journey cancellation failed: ${error.message}`);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    async updateJourneyPaymentStatus(journeyId, paymentStatus) {
        try {
            const journey = await Journey.findById(journeyId);
            
            if (!journey) {
                throw new Error('Journey not found');
            }
            
            journey.paymentStatus = paymentStatus;
            
            if (paymentStatus === 'paid') {
                // Generate ticket number if not already generated
                if (!journey.ticketNumber) {
                    const date = new Date();
                    const dateStr = date.getFullYear().toString() +
                        (date.getMonth() + 1).toString().padStart(2, '0') +
                        date.getDate().toString().padStart(2, '0');
                    const random = Math.floor(1000 + Math.random() * 9000);
                    journey.ticketNumber = `BUS-${dateStr}-${random}`;
                }
            }
            
            await journey.save();
            
            logger.info(`Journey payment status updated: ${journey._id} to ${paymentStatus}`);
            
            return {
                success: true,
                data: journey
            };
        } catch (error) {
            logger.error(`Journey payment status update failed: ${error.message}`);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async updateMultipleJourneyPaymentStatus(journeyIds, paymentStatus) {
        try {
            if (!journeyIds || journeyIds.length === 0) {
                return {
                    success: false,
                    error: 'No journey IDs provided'
                };
            }
            
            const updatePromises = journeyIds.map(journeyId => 
                this.updateJourneyPaymentStatus(journeyId, paymentStatus)
            );
            
            const results = await Promise.all(updatePromises);
            
            // Check if all updates were successful
            const allSuccessful = results.every(result => result.success);
            
            if (!allSuccessful) {
                const failedJourneys = results
                    .filter(result => !result.success)
                    .map(result => result.error);
                    
                logger.error(`Some journeys failed to update: ${failedJourneys.join(', ')}`);
            }
            
            return {
                success: allSuccessful,
                data: results.filter(result => result.success).map(result => result.data)
            };
        } catch (error) {
            logger.error(`Failed to update multiple journeys: ${error.message}`);
            return {
                success: false,
                error: error.message
            };
        }
    }
}

module.exports = new JourneyService();
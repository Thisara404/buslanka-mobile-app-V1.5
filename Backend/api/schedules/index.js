const express = require('express');
const router = express.Router();
const scheduleController = require('../../controllers/schedule.controller');
const paymentController = require('../../controllers/schedule.payment.controller');
const { verifyToken, authorize } = require('../../middleware/auth');

// Public routes - can be accessed without authentication
router.get('/route/:routeId', scheduleController.getSchedulesByRoute);
router.get('/:id', scheduleController.getScheduleById);

// Public route for schedule with fare
router.get('/:id/with-fare', scheduleController.getScheduleWithFare);

// Protected routes - require authentication
router.use(verifyToken);

// Payment related routes for schedules
router.post('/:scheduleId/pay', paymentController.createSchedulePayment);
router.get('/:scheduleId/fare', paymentController.getScheduleFare);

// Driver-specific routes
router.post('/', authorize(['driver']), scheduleController.createSchedule);
router.put('/:id/status', authorize(['driver']), scheduleController.updateScheduleStatus);
// Add this new route for general schedule updates
router.put('/:id', authorize(['driver']), scheduleController.updateSchedule);

// Add these routes for complete functionality
router.post('/:id/stop-times', authorize(['driver']), scheduleController.createStopTimes);
router.get('/:scheduleId/stop-times', scheduleController.getEstimatedArrivalTimes);
router.get('/:scheduleId/stop-times/:stopId', scheduleController.getEstimatedArrivalTimes);
router.delete('/:id', authorize(['driver']), scheduleController.deleteSchedule);

module.exports = router;
const express = require('express');
const { verifyToken } = require('../middleware/auth');
const journeyController = require('../controllers/journey.controller');

const router = express.Router();

// Protected routes
router.use(verifyToken);

// Journey booking and management
router.post('/book', journeyController.bookJourney);
router.get('/passenger', journeyController.getPassengerJourneys);
router.get('/:journeyId', journeyController.getJourneyDetails);
router.post('/:journeyId/cancel', journeyController.cancelJourney);
router.post('/:journeyId/verify', journeyController.verifyJourney);

// Payment related
router.post('/:journeyId/pay', journeyController.initiatePayment);

module.exports = router;
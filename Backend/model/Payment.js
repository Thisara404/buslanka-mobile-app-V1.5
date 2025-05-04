const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    journeyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Journey',
        required: true
    },
    // Add support for multiple journeys
    additionalJourneys: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Journey'
    }],
    passengerCount: {
        type: Number,
        default: 1,
        min: 1,
        max: 10
    },
    passengerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Passenger',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'USD'
    },
    status: {
        type: String,
        enum: ['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED', 'REFUND_FAILED'],
        default: 'PENDING'
    },
    paypalOrderId: {
        type: String
    },
    payerId: {
        type: String
    },
    transactionDetails: {
        captureId: String,
        paymentMethod: String,
        processorResponse: {
            code: String,
            message: String
        },
        merchantId: String,
        paymentTimestamp: Date
    },
    metadata: {
        ipAddress: String,
        userAgent: String,
        requestId: String,
        attemptCount: {
            type: Number,
            default: 0
        },
        passengerCount: {
            type: Number,
            default: 1
        },
        journeys: [{ type: String }]
    },
    refundDetails: {
        refundId: String,
        reason: String,
        refundedAt: Date,
        status: {
            type: String,
            enum: ['COMPLETED', 'FAILED', 'PENDING']
        },
        amount: Number,
        processorResponse: {
            code: String,
            message: String
        }
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
paymentSchema.index({ journeyId: 1 });
paymentSchema.index({ passengerId: 1 });
paymentSchema.index({ status: 1 });
paymentSchema.index({ createdAt: -1 });
paymentSchema.index({ additionalJourneys: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
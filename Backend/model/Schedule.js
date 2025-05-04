const mongoose = require("mongoose");

const stopTimeSchema = new mongoose.Schema({
  stopId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  stopName: String,
  arrivalTime: Date,
  departureTime: Date
});

const scheduleSchema = new mongoose.Schema({
  routeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route',
    required: true
  },
  // vehicleId: {
  //   type: mongoose.Schema.Types.ObjectId,
  //   ref: 'Vehicle',
  // },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
  },
  dayOfWeek: {
    type: [String],
    enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    required: true
  },
  startTime: {
    type: Date,
    required: true
  },
  endTime: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['scheduled', 'in-progress', 'completed', 'cancelled'],
    default: 'scheduled'
  },
  stopTimes: [stopTimeSchema],
  isRecurring: {
    type: Boolean,
    default: true
  }
}, { timestamps: true });

// Compound index for efficient schedule lookups
scheduleSchema.index({ routeId: 1, dayOfWeek: 1, startTime: 1 });

const Schedule = mongoose.model("Schedule", scheduleSchema);
module.exports = Schedule;
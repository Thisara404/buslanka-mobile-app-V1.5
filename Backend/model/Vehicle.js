// const mongoose = require("mongoose");

// const vehicleSchema = new mongoose.Schema({
//   busNumber: {
//     type: String,
//     required: true,
//     unique: true,
//   },
//   busModel: String,
//   busColor: String,
//   capacity: Number,
//   currentLocation: {
//     type: {
//       type: String,
//       enum: ['Point'],
//       default: 'Point'
//     },
//     coordinates: {
//       type: [Number], // [longitude, latitude]
//       default: [0, 0]
//     }
//   },
//   status: {
//     type: String,
//     enum: ['active', 'maintenance', 'inactive'],
//     default: 'inactive'
//   },
//   driver: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'Driver'
//   },
//   route: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'Route'
//   },
//   currentSchedule: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'Schedule'
//   }
// }, { timestamps: true });

// // Index for geospatial queries
// vehicleSchema.index({ currentLocation: '2dsphere' });

// const Vehicle = mongoose.model("Vehicle", vehicleSchema);
// module.exports = Vehicle;
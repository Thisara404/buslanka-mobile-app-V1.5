const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const passengerSchema = new mongoose.Schema({
  image: {
    type: String, // URL to image or base64 encoded image
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  phone: {
    type: String,
    required: true,
    unique: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
  },
  addresses: {
    home: {
      type: String,
      required: true,
    },
    work: String,
    shop: String,
  },
  favoriteRoutes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route'
  }]
}, { timestamps: true });

// Password hashing middleware
passengerSchema.pre("save", async function () {
  if (!this.isModified('password')) return;
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  } catch (error) {
    throw error;
  }
});

const Passenger = mongoose.model("Passenger", passengerSchema);
module.exports = Passenger;
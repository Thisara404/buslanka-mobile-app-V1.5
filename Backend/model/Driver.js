const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const driverSchema = new mongoose.Schema({
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
  address: {
    type: String,
    required: true,
  },
  busDetails: {
    busColor: String,
    busModel: String,
    busNumber: {
      type: String,
      required: true,
      unique: true,
    }
  },
  vehicle: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle'
  }
}, { timestamps: true });

// Password hashing middleware
driverSchema.pre("save", async function () {
  if (!this.isModified('password')) return;
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  } catch (error) {
    throw error;
  }
});

const Driver = mongoose.model("Driver", driverSchema);
module.exports = Driver;
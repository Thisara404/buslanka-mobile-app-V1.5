const mongoose = require("mongoose");

// Log connection attempt with masked password
const connectionString = process.env.MONGODB_URI;
const maskedConnectionString = connectionString ? connectionString.replace(/:([^@]+)@/, ':****@') : '';

console.log(`Attempting MongoDB connection: ${maskedConnectionString}`);

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(connectionString, {
      // These options are no longer needed in newer Mongoose versions,
      // but keeping them for compatibility with older versions
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("MongoDB connected successfully ! from DB.js");
    return mongoose.connection;
  } catch (error) {
    console.error("MongoDB connection error:", error.message);
    // Exit process with failure
    process.exit(1);
  }
};

module.exports = connectDB;
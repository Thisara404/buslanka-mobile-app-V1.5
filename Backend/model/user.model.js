// const mongoose = require("mongoose");
// const bcrypt = require("bcrypt");

// const userSchema = new mongoose.Schema({
//   username: {
//     type: String,
//     required: true,
//     trim: true
//   },
//   email: {
//     type: String,
//     required: true,
//     unique: true,
//     lowercase: true
//   },
//   password: {
//     type: String,
//     required: true
//   }
// }, { timestamps: true });

// // Password hashing middleware
// userSchema.pre("save", async function() {
//   if (!this.isModified('password')) return;
  
//   try {
//     const salt = await bcrypt.genSalt(10);
//     this.password = await bcrypt.hash(this.password, salt);
//   } catch (error) {
//     throw error;
//   }
// });

// const User = mongoose.model("User", userSchema);
// module.exports = User;
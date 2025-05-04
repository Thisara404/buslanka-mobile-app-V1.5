// At the top of your application entry point
require('dotenv').config();
const UserModel = require("../model/user.model");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

class UserService {
  static async registerUser(username, email, password) {
    try {
      // Check if user already exists
      const existingUser = await UserModel.findOne({ email });
      if (existingUser) {
        throw new Error("Email already in use");
      }
      
      // Create new user
      const createUser = new UserModel({ username, email, password });
      return await createUser.save();
    } catch (err) {
      throw err;
    }
  }

  static async loginUser(email, password) {
    try {
      const user = await UserModel.findOne({ email });
      if (!user) {
        throw new Error("User not found");
      }
      
      const isValid = await bcrypt.compare(password, user.password);
      if (!isValid) {
        throw new Error("Invalid password");
      }
      
      // Generate JWT token
      const token = jwt.sign(
        { userId: user._id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: "1d" }
      );
      
      return { 
        _id: user._id,
        username: user.username,
        email: user.email,
        token
      };
    } catch (err) {
      throw err;
    }
  }
}

module.exports = UserService;

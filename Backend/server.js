require('dotenv').config();

const app = require("./app");
const mongoose = require('mongoose');
const http = require('http');
const socketIO = require('socket.io');
const socketHandler = require('./sockets');

const PORT = process.env.PORT || 3001;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = socketIO(server, {
  cors: {
    origin: process.env.CLIENT_URL || "*",
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Make io accessible in Express routes
app.set('io', io);

// Set up socket handlers
socketHandler(io);

// More detailed error logging
app.use((err, req, res, next) => {
  console.error('Error details:', {
    method: req.method,
    path: req.path,
    body: req.body,
    query: req.query,
    params: req.params,
    error: err.stack
  });
  next(err);
});

// Connect to MongoDB
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    console.log("MongoDB connected successfully from server.js");
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err);
  });

server.listen(PORT, () => {
  console.log(`Server is running on port http://localhost:${PORT}`);
  console.log(`Socket.IO server is running`);
});

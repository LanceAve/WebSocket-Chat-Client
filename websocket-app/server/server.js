// server.js
require('dotenv').config();
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const mongoose = require('mongoose');
const path = require('path');

const { setupSocketServer } = require('./socketHandler');
const { log, error } = require('./logger');

const app = express();
const PORT = process.env.PORT || 8080;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost/websocket-chat';

// Serve static files from /public
app.use(express.static(path.join(__dirname, '../public')));

// Create an HTTP server and attach both Express and WebSocket
const server = http.createServer(app);
const wsServer = new WebSocket.Server({ server });

mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  log('Connected to MongoDB');

  // Attach WebSocket handler
  setupSocketServer(wsServer);

  // Start HTTP server (and by extension, WS server too)
  server.listen(PORT, () => {
    log(`Server running at http://localhost:${PORT}`);
    log(`WebSocket listening at ws://localhost:${PORT}`);
  });

}).catch(err => {
  error('MongoDB connection error:', err);
});
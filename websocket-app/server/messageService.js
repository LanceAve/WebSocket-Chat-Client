// messageService.js
const Message = require('./messageModel');

async function saveMessage({ username, message, clientType }) {
  const newMsg = new Message({ username, message, clientType });
  return await newMsg.save();
}

async function getRecentMessages(limit = 10) {
  return await Message.find().sort({ timestamp: -1 }).limit(limit).lean();
}

module.exports = { saveMessage, getRecentMessages };
// socketHandler.js
const { saveMessage, getRecentMessages } = require('./messageService');
const { log, error } = require('./logger');

const clients = new Map();

function setupSocketServer(wsServer) {
  wsServer.on('connection', async (ws) => {
    log('New client connected');
    let username = `User-${Math.floor(Math.random() * 1000)}`;

    clients.set(ws, username);

    // Send chat history
    const history = await getRecentMessages();
    history.reverse().forEach(msg => ws.send(JSON.stringify(msg)));

    ws.send(JSON.stringify({
      username: 'Server',
      message: `Welcome, ${username}! Please identify yourself.`,
      timestamp: new Date()
    }));

    ws.on('message', async (data) => {
      try {
        const parsed = JSON.parse(data);

        if (parsed.username && parsed.clientType) {
          // Identification message
          username = `${parsed.clientType}-${Math.floor(Math.random() * 1000)}`;
          clients.set(ws, username);
          ws.send(JSON.stringify({
            username: 'Server',
            message: `You are now identified as ${username}`,
            timestamp: new Date()
          }));
          return;
        }

        if (!parsed.message) return;

        const timestamp = new Date();
        const clientType = username.split('-')[0] || 'Other';

        await saveMessage({ username, message: parsed.message, clientType });

        const messagePayload = JSON.stringify({ username, message: parsed.message, timestamp });

        for (const [client] of clients) {
          if (client.readyState === ws.OPEN) {
            client.send(messagePayload);
          }
        }

      } catch (err) {
        error('Message handling failed:', err);
      }
    });

    ws.on('close', () => {
      log(`${username} disconnected.`);
      clients.delete(ws);
    });

    ws.on('error', (err) => error(`Socket error from ${username}:`, err));
  });
}

module.exports = { setupSocketServer };
// logger.js
const log = (...args) => console.log('[INFO]', ...args);
const warn = (...args) => console.warn('[WARN]', ...args);
const error = (...args) => console.error('[ERROR]', ...args);

module.exports = { log, warn, error };
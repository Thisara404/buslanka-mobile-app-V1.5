const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Log file paths
const errorLogPath = path.join(logsDir, 'error.log');
const infoLogPath = path.join(logsDir, 'info.log');

// Get current timestamp
const getTimestamp = () => {
    return new Date().toISOString();
};

// Write to log file
const writeToFile = (filePath, message) => {
    const timestamp = getTimestamp();
    const logEntry = `[${timestamp}] ${message}\n`;
    
    fs.appendFile(filePath, logEntry, (err) => {
        if (err) {
            console.error(`Error writing to log file: ${err.message}`);
        }
    });
};

// Logger methods
const logger = {
    info: (message) => {
        const formattedMessage = typeof message === 'object' 
            ? JSON.stringify(message) 
            : message;
        
        console.log(`[INFO] ${formattedMessage}`);
        writeToFile(infoLogPath, `INFO: ${formattedMessage}`);
    },
    
    error: (message, error) => {
        const errorDetails = error ? `: ${error.stack || error.message || error}` : '';
        const formattedMessage = typeof message === 'object' 
            ? JSON.stringify(message) 
            : message;
            
        console.error(`[ERROR] ${formattedMessage}${errorDetails}`);
        writeToFile(errorLogPath, `ERROR: ${formattedMessage}${errorDetails}`);
    },
    
    warn: (message) => {
        const formattedMessage = typeof message === 'object' 
            ? JSON.stringify(message) 
            : message;
            
        console.warn(`[WARN] ${formattedMessage}`);
        writeToFile(infoLogPath, `WARN: ${formattedMessage}`);
    },
    
    debug: (message) => {
        if (process.env.NODE_ENV === 'development') {
            const formattedMessage = typeof message === 'object' 
                ? JSON.stringify(message) 
                : message;
                
            console.debug(`[DEBUG] ${formattedMessage}`);
            writeToFile(infoLogPath, `DEBUG: ${formattedMessage}`);
        }
    }
};

module.exports = logger;
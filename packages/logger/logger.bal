import ballerina/log;
import ballerina/time;

# Log levels
public enum LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

# Logger configuration
public type LoggerConfig record {
    LogLevel level;
    boolean includeTimestamp;
    boolean includeLocation;
    string format?;
};

# Custom logger class
public class Logger {
    private LoggerConfig config;

    public function init(LoggerConfig config) {
        self.config = config;
    }

    # Log debug messages
    public function debug(string message, map<anydata>? context = ()) {
        if self.shouldLog(DEBUG) {
            self.logMessage(DEBUG, message, context);
        }
    }

    # Log info messages
    public function info(string message, map<anydata>? context = ()) {
        if self.shouldLog(INFO) {
            self.logMessage(INFO, message, context);
        }
    }

    # Log warning messages
    public function warn(string message, map<anydata>? context = ()) {
        if self.shouldLog(WARN) {
            self.logMessage(WARN, message, context);
        }
    }

    # Log error messages
    public function error(string message, map<anydata>? context = (), error? err = ()) {
        if self.shouldLog(ERROR) {
            map<anydata> fullContext = context ?: {};
            if err is error {
                fullContext["error"] = err.message();
                fullContext["stack"] = err.stackTrace();
            }
            self.logMessage(ERROR, message, fullContext);
        }
    }

    # Check if log level should be logged
    private function shouldLog(LogLevel level) returns boolean {
        return level >= self.config.level;
    }

    # Format and log the message
    private function logMessage(LogLevel level, string message, map<anydata>? context) {
        string formattedMessage = self.formatMessage(level, message, context);
        
        match level {
            DEBUG => log:printDebug(formattedMessage);
            INFO => log:printInfo(formattedMessage);
            WARN => log:printWarn(formattedMessage);
            ERROR => log:printError(formattedMessage);
        }
    }

    # Format the log message
    private function formatMessage(LogLevel level, string message, map<anydata>? context) returns string {
        string formatted = message;

        if self.config.includeTimestamp {
            time:Utc utc = time:utcNow();
            string timestamp = time:utcToString(utc);
            formatted = string `[${timestamp}] ${formatted}`;
        }

        if context is map<anydata> && context.length() > 0 {
            formatted = string `${formatted} | Context: ${context.toString()}`;
        }

        return formatted;
    }
}

# Default logger instance
public Logger defaultLogger = new({
    level: INFO,
    includeTimestamp: true,
    includeLocation: false
});

# Convenience functions using default logger
public function logDebug(string message, map<anydata>? context = ()) {
    defaultLogger.debug(message, context);
}

public function logInfo(string message, map<anydata>? context = ()) {
    defaultLogger.info(message, context);
}

public function logWarn(string message, map<anydata>? context = ()) {
    defaultLogger.warn(message, context);
}

public function logError(string message, map<anydata>? context = (), error? err = ()) {
    defaultLogger.error(message, context, err);
}

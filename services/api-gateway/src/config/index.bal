import ballerina/os;

# Application configuration
public type AppConfig record {|
    # Host address for the API gateway
    string host;
    # Port number for the API gateway
    int port;
    # Log level for the application
    string logLevel;
|};

# Redis configuration
public type RedisConfig record {|
    # Redis host address
    string host;
    # Redis port number
    int port;
    # Redis password
    string password;
|};

# Kafka configuration
public type KafkaConfig record {|
    # Kafka bootstrap servers
    string bootstrapServers;
    # Kafka consumer group
    string consumerGroup;
|};

# Service URLs configuration
public type ServiceUrls record {|
    # User service URL
    string userService;
    # Appointment service URL
    string appointmentService;
    # Lab report service URL
    string labReportService;
|};

# Rate limiting configuration
public type RateLimitConfig record {|
    # Time window in milliseconds
    int windowMs;
    # Maximum requests per window
    int maxRequests;
|};

# Main configuration type
public type Config record {|
    # Application configuration
    AppConfig app;
    # Redis configuration
    RedisConfig redis;
    # Kafka configuration
    KafkaConfig kafka;
    # Service URLs
    ServiceUrls services;
    # Rate limiting configuration
    RateLimitConfig rateLimit;
|};

# Load configuration from environment variables
# + return - Configuration object
public function loadConfig() returns Config {
    return {
        app: {
            host: getEnvVar("API_GATEWAY_HOST", "0.0.0.0"),
            port: checkpanic int:fromString(getEnvVar("API_GATEWAY_PORT", "8080")),
            logLevel: getEnvVar("LOG_LEVEL", "INFO")
        },
        redis: {
            host: getEnvVar("REDIS_HOST", "localhost"),
            port: checkpanic int:fromString(getEnvVar("REDIS_PORT", "6379")),
            password: getEnvVar("REDIS_PASSWORD", "")
        },
        kafka: {
            bootstrapServers: getEnvVar("KAFKA_BOOTSTRAP_SERVERS", "localhost:9094"),
            consumerGroup: getEnvVar("KAFKA_CONSUMER_GROUP", "api-gateway")
        },
        services: {
            userService: getEnvVar("USER_SERVICE_URL", "http://localhost:3001"),
            appointmentService: getEnvVar("APPOINTMENT_SERVICE_URL", "http://localhost:3002"),
            labReportService: getEnvVar("LAB_REPORT_SERVICE_URL", "http://localhost:3100")
        },
        rateLimit: {
            windowMs: checkpanic int:fromString(getEnvVar("RATE_LIMIT_WINDOW", "60000")),
            maxRequests: checkpanic int:fromString(getEnvVar("RATE_LIMIT_MAX_REQUESTS", "100"))
        }
    };
}

# Helper function to get environment variable with default
# + key - Environment variable key
# + defaultValue - Default value if environment variable is not set
# + return - Environment variable value or default
function getEnvVar(string key, string defaultValue) returns string {
    string? value = os:getEnv(key);
    return value is string ? value : defaultValue;
}

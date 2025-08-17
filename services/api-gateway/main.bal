import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerina/time;

# Configuration types
type AppConfig record {|
    # Gateway host address
    string host;
    # Gateway port number
    int port;
    # Application log level
    string logLevel;
|};

type RedisConfig record {|
    # Redis server host
    string host;
    # Redis server port
    int port;
    # Redis server password
    string password;
|};

type KafkaConfig record {|
    # Kafka bootstrap servers
    string bootstrapServers;
    # Kafka consumer group ID
    string consumerGroup;
|};

public type ServiceUrls record {|
    # User service URL
    string userService;
    # Appointment service URL
    string appointmentService;
    # Lab report service URL
    string labReportService;
|};

public type RateLimitConfig record {|
    # Rate limit time window in milliseconds
    int windowMs;
    # Maximum requests per window
    int maxRequests;
|};

type Config record {|
    # Application configuration
    AppConfig app;
    # Redis configuration
    RedisConfig redis;
    # Kafka configuration
    KafkaConfig kafka;
    # Service URLs configuration
    ServiceUrls services;
    # Rate limiting configuration
    RateLimitConfig rateLimit;
|};

# Global configuration
Config appConfig = loadConfig();

# Log startup information
function init() {
    log:printInfo("=================================================");
    log:printInfo("         MediLink API Gateway Starting          ");
    log:printInfo("=================================================");
    log:printInfo(string `Host: ${appConfig.app.host}`);
    log:printInfo(string `Port: ${appConfig.app.port}`);
    log:printInfo(string `Log Level: ${appConfig.app.logLevel}`);
    log:printInfo("Available endpoints:");
    log:printInfo(string `  - Health: http://${appConfig.app.host}:${appConfig.app.port}/api/health`);
    log:printInfo(string `  - Reports: http://${appConfig.app.host}:${appConfig.app.port}/api/reports/*`);
    log:printInfo("=================================================");
    log:printInfo("API Gateway is ready to accept requests!");
    log:printInfo("=================================================");
}

# Main API Gateway service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    }
}
service /api on new http:Listener(appConfig.app.port, config = {host: appConfig.app.host}) {

    # Health check endpoint
    # + return - Health status response
    resource function get health() returns json {
        log:printInfo("Health check endpoint accessed");
        return {
            "status": "OK",
            "service": "API Gateway",
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # User service routes
    # Base users route
    # + req - HTTP request
    # + return - HTTP response from user service
    resource function 'default users(http:Request req) returns http:Response|error {
        return check forwardToService("user", "/users", req);
    }

    # User service routes with path
    # + path - Path parameters
    # + req - HTTP request
    # + return - HTTP response from user service
    resource function 'default users/[string... path](http:Request req) returns http:Response|error {
        return check forwardToService("user", string `/users/${string:'join("/", ...path)}`, req);
    }

    # Appointment service routes
    # Base appointments route
    # + req - HTTP request
    # + return - HTTP response from appointment service
    resource function 'default appointments(http:Request req) returns http:Response|error {
        return check forwardToService("appointment", "/appointments", req);
    }

    # Appointment service routes with path
    # + path - Path parameters
    # + req - HTTP request
    # + return - HTTP response from appointment service
    resource function 'default appointments/[string... path](http:Request req) returns http:Response|error {
        return check forwardToService("appointment", string `/appointments/${string:'join("/", ...path)}`, req);
    }

    # Lab report service routes
    # Base reports route
    # + req - HTTP request
    # + return - HTTP response from lab report service
    resource function 'default reports(http:Request req) returns http:Response|error {
        return check forwardToService("labReport", "/reports", req);
    }

    # Lab report service routes with path
    # + path - Path parameters
    # + req - HTTP request
    # + return - HTTP response from lab report service
    resource function 'default reports/[string... path](http:Request req) returns http:Response|error {
        return check forwardToService("labReport", string `/reports/${string:'join("/", ...path)}`, req);
    }

    # Default route for unhandled paths
    # + path - Path parameters
    # + req - HTTP request
    # + return - 404 error response
    resource function 'default [string... path](http:Request req) returns http:Response|error {
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload({
            "error": "Not Found",
            "message": string `Route not found: ${string:'join("/", ...path)}`,
            "timestamp": time:utcToString(time:utcNow())
        });
        return response;
    }
}

# Forward request to appropriate service
# + serviceName - Name of the target service
# + path - Request path to forward
# + request - HTTP request to forward
# + return - HTTP response from the target service
function forwardToService(string serviceName, string path, http:Request request) returns http:Response|error {

    string serviceUrl = getServiceUrl(serviceName);
    log:printInfo(string `Forwarding ${request.method} ${path} to ${serviceName} service`);
    log:printInfo(string `Service URL: ${serviceUrl}`);
    log:printInfo(string `Full request URL will be: ${serviceUrl}${path}`);

    // Create HTTP client for the service
    http:Client serviceClient = check new (serviceUrl);

    // Forward the request based on method
    if request.method == "GET" {
        return check serviceClient->get(path);
    } else if request.method == "POST" {
        return check serviceClient->post(path, request);
    } else if request.method == "PUT" {
        return check serviceClient->put(path, request);
    } else if request.method == "DELETE" {
        return check serviceClient->delete(path, request);
    } else if request.method == "PATCH" {
        return check serviceClient->patch(path, request);
    } else {
        http:Response errorResponse = new;
        errorResponse.statusCode = 405;
        errorResponse.setJsonPayload({
            "error": "Method Not Allowed",
            "message": string `HTTP method ${request.method} not supported`
        });
        return errorResponse;
    }
}

# Get service URL by service name
# + serviceName - Name of the service
# + return - Base URL of the service
function getServiceUrl(string serviceName) returns string {
    if serviceName == "user" {
        return appConfig.services.userService;
    } else if serviceName == "appointment" {
        return appConfig.services.appointmentService;
    } else if serviceName == "labReport" {
        return appConfig.services.labReportService;
    } else {
        return "http://localhost:3000"; // Default fallback
    }
}

# Load configuration from environment variables
# + return - Application configuration
function loadConfig() returns Config {
    return {
        app: {
            host: getEnvVar("API_GATEWAY_HOST", "0.0.0.0"),
            port: getIntEnvVar("API_GATEWAY_PORT", 3000),
            logLevel: getEnvVar("LOG_LEVEL", "INFO")
        },
        redis: {
            host: getEnvVar("REDIS_HOST", "localhost"),
            port: getIntEnvVar("REDIS_PORT", 6379),
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
            windowMs: getIntEnvVar("RATE_LIMIT_WINDOW", 60000),
            maxRequests: getIntEnvVar("RATE_LIMIT_MAX_REQUESTS", 100)
        }
    };
}

# Helper function to get environment variable with default
# + key - Environment variable key
# + defaultValue - Default value if environment variable is not set
# + return - Environment variable value or default value
function getEnvVar(string key, string defaultValue) returns string {
    string? value = os:getEnv(key);
    return value is string ? value : defaultValue;
}

# Helper function to get integer environment variable with default
# + key - Environment variable key
# + defaultValue - Default integer value if environment variable is not set or invalid
# + return - Environment variable value as integer or default value
function getIntEnvVar(string key, int defaultValue) returns int {
    string? value = os:getEnv(key);
    if value is string && value.trim() != "" {
        int|error intValue = int:fromString(value);
        if intValue is int {
            return intValue;
        }
    }
    return defaultValue;
}

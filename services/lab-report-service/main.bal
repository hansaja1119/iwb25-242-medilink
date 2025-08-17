import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerina/time;
import ballerina/uuid;

# Configuration types
type AppConfig record {|
    # Service host address
    string host;
    # Service port number
    int port;
    # Application log level
    string logLevel;
|};

type DatabaseConfig record {|
    # Database host
    string host;
    # Database port
    int port;
    # Database name
    string name;
    # Database username
    string username;
    # Database password
    string password;
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

type Config record {|
    # Application configuration
    AppConfig app;
    # Database configuration
    DatabaseConfig database;
    # Redis configuration
    RedisConfig redis;
    # Kafka configuration
    KafkaConfig kafka;
|};

# Global configuration
Config appConfig = loadConfig();

# Service initialization
function init() {
    log:printInfo("=================================================");
    log:printInfo("      MediLink Lab Report Service Starting      ");
    log:printInfo("=================================================");
    log:printInfo(string `Host: ${appConfig.app.host}`);
    log:printInfo(string `Port: ${appConfig.app.port}`);
    log:printInfo(string `Log Level: ${appConfig.app.logLevel}`);
    log:printInfo("Available endpoints:");
    log:printInfo(string `  - Health: http://${appConfig.app.host}:${appConfig.app.port}/health`);
    log:printInfo(string `  - Reports: http://${appConfig.app.host}:${appConfig.app.port}/reports/*`);
    log:printInfo(string `  - Templates: http://${appConfig.app.host}:${appConfig.app.port}/templates/*`);
    log:printInfo(string `  - Workflow: http://${appConfig.app.host}:${appConfig.app.port}/workflow/*`);
    log:printInfo("=================================================");
    log:printInfo("Lab Report Service is ready to accept requests!");
    log:printInfo("=================================================");
}

# Main Lab Report Service
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    }
}
service / on new http:Listener(appConfig.app.port, config = {host: appConfig.app.host}) {

    # Health check endpoint
    # + return - Health status response
    resource function get health() returns json {
        log:printInfo("Health check endpoint accessed");
        return {
            "status": "OK",
            "service": "Lab Report Service",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "0.1.0"
        };
    }

    # Reports endpoints
    # + return - Reports response
    resource function get reports() returns json|error {
        log:printInfo("GET /reports - List all reports");
        return {
            "message": "List all lab reports",
            "data": [],
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Get specific report
    # + reportId - Report ID
    # + return - Report response
    resource function get reports/[string reportId]() returns json|error {
        log:printInfo(string `GET /reports/${reportId} - Get specific report`);
        return {
            "message": string `Get report ${reportId}`,
            "data": {
                "id": reportId,
                "status": "pending",
                "createdAt": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Create new report
    # + request - HTTP request with report data
    # + return - Created report response
    resource function post reports(http:Request request) returns json|error {
        log:printInfo("POST /reports - Create new report");
        json|error payload = request.getJsonPayload();
        if payload is error {
            return {
                "error": "Invalid JSON payload",
                "timestamp": time:utcToString(time:utcNow())
            };
        }

        string reportId = uuid:createType1AsString();
        return {
            "message": "Report created successfully",
            "data": {
                "id": reportId,
                "status": "created",
                "payload": payload,
                "createdAt": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Templates endpoints
    # + return - Templates response
    resource function get templates() returns json|error {
        log:printInfo("GET /templates - List all templates");
        return {
            "message": "List all lab report templates",
            "data": [],
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Workflow endpoints
    # + return - Workflow response
    resource function get workflow() returns json|error {
        log:printInfo("GET /workflow - Get workflow status");
        return {
            "message": "Lab workflow status",
            "data": {
                "activeWorkflows": 0,
                "pendingReports": 0,
                "completedReports": 0
            },
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Start workflow
    # + request - HTTP request with workflow data
    # + return - Workflow response
    resource function post workflow(http:Request request) returns json|error {
        log:printInfo("POST /workflow - Start new workflow");
        json|error payload = request.getJsonPayload();
        if payload is error {
            return {
                "error": "Invalid JSON payload",
                "timestamp": time:utcToString(time:utcNow())
            };
        }

        string workflowId = uuid:createType1AsString();
        return {
            "message": "Workflow started successfully",
            "data": {
                "workflowId": workflowId,
                "status": "started",
                "payload": payload,
                "startedAt": time:utcToString(time:utcNow())
            },
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Default route for unhandled paths
    # + path - Path parameters
    # + req - HTTP request
    # + return - 404 error response
    resource function 'default [string... path](http:Request req) returns http:Response|error {
        log:printInfo(string `404 - Route not found: ${string:'join("/", ...path)}`);
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

# Load configuration from environment variables
# + return - Application configuration
function loadConfig() returns Config {
    return {
        app: {
            host: getEnvVar("LAB_REPORT_SERVICE_HOST", "0.0.0.0"),
            port: getIntEnvVar("LAB_REPORT_SERVICE_PORT", 3100),
            logLevel: getEnvVar("LOG_LEVEL", "INFO")
        },
        database: {
            host: getEnvVar("DB_HOST", "localhost"),
            port: getIntEnvVar("DB_PORT", 5432),
            name: getEnvVar("DB_NAME", "medilink_lab"),
            username: getEnvVar("DB_USERNAME", "postgres"),
            password: getEnvVar("DB_PASSWORD", "")
        },
        redis: {
            host: getEnvVar("REDIS_HOST", "localhost"),
            port: getIntEnvVar("REDIS_PORT", 6379),
            password: getEnvVar("REDIS_PASSWORD", "")
        },
        kafka: {
            bootstrapServers: getEnvVar("KAFKA_BOOTSTRAP_SERVERS", "localhost:9094"),
            consumerGroup: getEnvVar("KAFKA_CONSUMER_GROUP", "lab-report-service")
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

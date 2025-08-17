# Request and Response types
public type ApiResponse record {|
    # Status of the response
    string status;
    # Response message
    string message;
    # Response data
    anydata data?;
    # Timestamp of the response
    string timestamp;
|};

# Error response type
public type ErrorResponse record {|
    # Error type
    string 'error;
    # Error message
    string message;
    # Error details
    anydata details?;
    # Timestamp of the error
    string timestamp;
|};

# Health check response
public type HealthResponse record {|
    # Service status
    string status;
    # Service name
    string 'service;
    # Current timestamp
    string timestamp;
    # Service version
    string 'version?;
|};

# Rate limit information
public type RateLimitInfo record {|
    # Maximum requests allowed
    int 'limit;
    # Remaining requests in current window
    int remaining;
    # Time until rate limit resets (in seconds)
    int reset;
    # Rate limit window in seconds
    int window;
|};

# Request metadata
public type RequestMetadata record {|
    # Client IP address
    string clientIp;
    # User agent
    string userAgent?;
    # Request ID for tracing
    string requestId?;
    # Timestamp when request was received
    string timestamp;
|};

# Service status
public type ServiceStatus record {|
    # Service name
    string name;
    # Service URL
    string url;
    # Service health status
    string status;
    # Last check timestamp
    string lastCheck;
|};

# Gateway metrics
public type GatewayMetrics record {|
    # Total requests processed
    int totalRequests;
    # Total errors encountered
    int totalErrors;
    # Average response time
    decimal avgResponseTime;
    # Uptime in seconds
    int uptime;
    # Active connections
    int activeConnections;
|};

# Service route configuration
public type RouteConfig record {|
    # Route path pattern
    string path;
    # Target service name
    string 'service;
    # HTTP methods allowed
    string[] methods;
    # Rate limit override
    int rateLimitOverride?;
    # Timeout override
    int timeoutOverride?;
|};

# Authentication info
public type AuthInfo record {|
    # User ID
    string userId?;
    # User roles
    string[] roles?;
    # Authentication token
    string token?;
    # Token expiry
    string expiry?;
|};

# Audit log entry
public type AuditLogEntry record {|
    # Request ID
    string requestId;
    # User ID (if authenticated)
    string userId?;
    # Client IP
    string clientIp;
    # HTTP method
    string method;
    # Request path
    string path;
    # Target service
    string targetService;
    # Response status code
    int statusCode;
    # Response time in milliseconds
    int responseTime;
    # Timestamp
    string timestamp;
    # Error message (if any)
    string 'error?;
|};

# Configuration for external service
public type ExternalServiceConfig record {|
    # Service name
    string name;
    # Base URL
    string baseUrl;
    # Timeout in milliseconds
    int timeout;
    # Retry attempts
    int retryAttempts;
    # Health check endpoint
    string healthCheckPath;
    # Circuit breaker settings
    CircuitBreakerConfig circuitBreaker?;
|};

# Circuit breaker configuration
public type CircuitBreakerConfig record {|
    # Failure threshold
    int failureThreshold;
    # Recovery timeout in milliseconds
    int recoveryTimeout;
    # Status check interval in milliseconds
    int statusCheckInterval;
|};

# Load balancer configuration
public type LoadBalancerConfig record {|
    # Load balancing strategy
    string strategy; // "round-robin", "least-connections", "weighted"
    # Service instances
    ServiceInstance[] instances;
|};

# Service instance for load balancing
public type ServiceInstance record {|
    # Instance URL
    string url;
    # Instance weight (for weighted load balancing)
    int weight;
    # Instance health status
    boolean healthy;
|};

# Cache configuration
public type CacheConfig record {|
    # Cache TTL in seconds
    int ttl;
    # Maximum cache size
    int maxSize;
    # Cache key patterns
    string[] keyPatterns;
|};

# Monitoring configuration
public type MonitoringConfig record {|
    # Enable metrics collection
    boolean enableMetrics;
    # Enable request logging
    boolean enableRequestLogging;
    # Enable health checks
    boolean enableHealthChecks;
    # Metrics export interval in seconds
    int metricsInterval;
|};

# Security configuration
public type SecurityConfig record {|
    # Enable CORS
    boolean enableCors;
    # CORS allowed origins
    string[] allowedOrigins;
    # Enable rate limiting
    boolean enableRateLimit;
    # Enable authentication
    boolean enableAuth;
    # JWT secret key
    string jwtSecret?;
|};

# WebSocket configuration
public type WebSocketConfig record {|
    # Enable WebSocket support
    boolean enabled;
    # WebSocket path prefix
    string pathPrefix;
    # Maximum connections
    int maxConnections;
    # Connection timeout in seconds
    int connectionTimeout;
|};

# File upload configuration
public type FileUploadConfig record {|
    # Maximum file size in bytes
    int maxFileSize;
    # Allowed file types
    string[] allowedTypes;
    # Upload path
    string uploadPath;
    # Enable virus scanning
    boolean enableVirusScanning;
|};

# API versioning configuration
public type VersioningConfig record {|
    # Versioning strategy
    string strategy; // "header", "path", "query"
    # Default version
    string defaultVersion;
    # Supported versions
    string[] supportedVersions;
    # Version header name (if using header strategy)
    string versionHeader?;
|};

# Transformation configuration
public type TransformationConfig record {|
    # Request transformations
    TransformRule[] requestTransforms;
    # Response transformations
    TransformRule[] responseTransforms;
|};

# Transformation rule
public type TransformRule record {|
    # Rule name
    string name;
    # Source path pattern
    string sourcePattern;
    # Target path pattern
    string targetPattern;
    # Transformation type
    string transformType; // "add", "remove", "modify", "rename"
|};

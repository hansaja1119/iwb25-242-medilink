import ballerina/http;
import ballerina/time;

# Rate limiter configuration
public type RateLimitConfig record {|
    # Time window in milliseconds
    int windowMs;
    # Maximum requests per window
    int maxRequests;
|};

# Rate limiter entry
type RateLimitEntry record {|
    int requestCount;
    int windowStart;
|};

# Rate limiter middleware
public class RateLimiter {
    private map<RateLimitEntry> rateLimitStore = {};
    public RateLimitConfig config;

    # Initialize rate limiter
    # + rateLimitConfig - Rate limit configuration
    public function init(RateLimitConfig rateLimitConfig) {
        self.config = rateLimitConfig;
    }

    # Check if request is allowed
    # + clientId - Client identifier (IP address or user ID)
    # + return - True if request is allowed, false otherwise
    public function isAllowed(string clientId) returns boolean {
        int currentTime = <int>time:monotonicNow();

        RateLimitEntry? entry = self.rateLimitStore[clientId];

        if entry is () {
            // First request from this client
            self.rateLimitStore[clientId] = {
                requestCount: 1,
                windowStart: currentTime
            };
            return true;
        }

        // Check if we're still in the same window
        int windowElapsed = currentTime - entry.windowStart;

        if windowElapsed >= self.config.windowMs {
            // New window, reset counter
            self.rateLimitStore[clientId] = {
                requestCount: 1,
                windowStart: currentTime
            };
            return true;
        }

        // Same window, check if limit exceeded
        if entry.requestCount >= self.config.maxRequests {
            return false;
        }

        // Increment counter
        entry.requestCount += 1;
        return true;
    }

    # Reset rate limit for a client
    # + clientId - Client identifier
    public function reset(string clientId) {
        _ = self.rateLimitStore.remove(clientId);
    }

    # Get remaining requests for a client
    # + clientId - Client identifier  
    # + return - Number of remaining requests in current window
    public function getRemainingRequests(string clientId) returns int {
        RateLimitEntry? entry = self.rateLimitStore[clientId];

        if entry is () {
            return self.config.maxRequests;
        }

        int currentTime = <int>time:monotonicNow();
        int windowElapsed = currentTime - entry.windowStart;

        if windowElapsed >= self.config.windowMs {
            return self.config.maxRequests;
        }

        return self.config.maxRequests - entry.requestCount;
    }

    # Get time until window reset
    # + clientId - Client identifier
    # + return - Time in milliseconds until window reset
    public function getTimeUntilReset(string clientId) returns int {
        RateLimitEntry? entry = self.rateLimitStore[clientId];

        if entry is () {
            return 0;
        }

        int currentTime = <int>time:monotonicNow();
        int windowElapsed = currentTime - entry.windowStart;

        if windowElapsed >= self.config.windowMs {
            return 0;
        }

        return self.config.windowMs - windowElapsed;
    }
}

# Rate limiter service interceptor
public service class RateLimiterInterceptor {
    *http:ResponseInterceptor;

    private RateLimiter rateLimiter;

    public function init(RateLimitConfig config) {
        self.rateLimiter = new (config);
    }

    public function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
        return ctx.next();
    }
}

# Rate limiter request service interceptor
public service class RateLimiterRequestInterceptor {
    *http:RequestInterceptor;

    private RateLimiter rateLimiter;

    public function init(RateLimitConfig config) {
        self.rateLimiter = new (config);
    }

    public function interceptRequest(http:RequestContext ctx, http:Request req) returns http:NextService|error? {
        string clientIp = getClientIp(req);

        if !self.rateLimiter.isAllowed(clientIp) {
            http:Response response = new;
            response.statusCode = 429;
            response.setTextPayload("Too Many Requests");
            response.setHeader("Retry-After", self.rateLimiter.getTimeUntilReset(clientIp).toString());
            response.setHeader("X-RateLimit-Limit", self.rateLimiter.config.maxRequests.toString());
            response.setHeader("X-RateLimit-Remaining", "0");
            response.setHeader("X-RateLimit-Reset", self.rateLimiter.getTimeUntilReset(clientIp).toString());

            ctx.respond(response);
            return;
        }

        // Add rate limit headers to response context
        int remaining = self.rateLimiter.getRemainingRequests(clientIp);
        int resetTime = self.rateLimiter.getTimeUntilReset(clientIp);

        // Store headers in context for later use
        ctx.set("X-RateLimit-Limit", self.rateLimiter.config.maxRequests.toString());
        ctx.set("X-RateLimit-Remaining", remaining.toString());
        ctx.set("X-RateLimit-Reset", resetTime.toString());

        return ctx.next();
    }
}

# Extract client IP from request
# + request - HTTP request
# + return - Client IP address
function getClientIp(http:Request request) returns string {
    // Try to get IP from X-Forwarded-For header (for proxied requests)
    string|http:HeaderNotFoundError xForwardedFor = request.getHeader("X-Forwarded-For");
    if xForwardedFor is string {
        // Take the first IP in case of multiple IPs
        string[] ips = re `,`.split(xForwardedFor);
        if ips.length() > 0 {
            return ips[0].trim();
        }
    }

    // Try to get IP from X-Real-IP header
    string|http:HeaderNotFoundError xRealIp = request.getHeader("X-Real-IP");
    if xRealIp is string {
        return xRealIp;
    }

    // Fallback to connection info (this might not be available in all scenarios)
    return "unknown";
}

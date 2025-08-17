import ballerina/redis;
import ballerina/log;

# Redis client configuration
public type RedisConfig record {
    string host;
    int port;
    string password?;
    int database?;
};

# Redis client class
public class RedisClient {
    private redis:Client redisClient;

    public function init(RedisConfig config) returns error? {
        redis:ConnectionConfig redisConfig = {
            host: config.host,
            port: config.port,
            password: config.password,
            database: config.database ?: 0
        };
        
        self.redisClient = check new (redisConfig);
        log:printInfo("Redis client connected successfully");
    }

    # Set a key-value pair with optional expiration
    public function set(string key, string value, int? expireInSeconds = ()) returns error? {
        if expireInSeconds is int {
            return self.redisClient->setEx(key, value, expireInSeconds);
        } else {
            return self.redisClient->set(key, value);
        }
    }

    # Get value by key
    public function get(string key) returns string|error? {
        return self.redisClient->get(key);
    }

    # Delete a key
    public function delete(string key) returns int|error {
        return self.redisClient->del([key]);
    }

    # Check if key exists
    public function exists(string key) returns boolean|error {
        int result = check self.redisClient->exists([key]);
        return result > 0;
    }

    # Increment a key
    public function increment(string key) returns int|error {
        return self.redisClient->incr(key);
    }

    # Set expiration for a key
    public function expire(string key, int seconds) returns boolean|error {
        return self.redisClient->expire(key, seconds);
    }

    # Get TTL for a key
    public function ttl(string key) returns int|error {
        return self.redisClient->ttl(key);
    }

    # Close the connection
    public function close() returns error? {
        return self.redisClient->close();
    }
}

# MediLink API Gateway - Ballerina Implementation

This is a Ballerina implementation of the MediLink API Gateway, providing a high-performance, scalable gateway for microservices communication with built-in rate limiting, service discovery, and load balancing capabilities.

## 🏗️ Architecture

The API Gateway serves as the single entry point for all client requests, routing them to appropriate microservices:

```
Client → API Gateway → [User Service | Medical-record Service | Lab Report Service]
```

## 🚀 Features

### Core Features

- **API Gateway**: Single entry point for all microservice requests
- **Service Routing**: Intelligent routing to User, Appointment, and Lab Report services
- **Rate Limiting**: Configurable rate limiting with Redis backend
- **CORS Support**: Cross-Origin Resource Sharing enabled
- **Health Checks**: Built-in health monitoring endpoints
- **Error Handling**: Comprehensive error handling and response formatting

### Middleware

- **Rate Limiter**: Request rate limiting per client IP
- **Logger**: Structured logging with configurable levels
- **CORS**: Cross-origin request handling

### Packages

- **Redis Client**: Custom Redis client with connection pooling
- **Kafka Client**: Kafka producer/consumer for event streaming
- **Logger**: Structured logging with multiple levels

### Configuration

- **Environment-based**: All configuration via environment variables
- **Service Discovery**: Dynamic service URL configuration
- **Security**: Configurable security settings

## 🛠️ Installation & Setup

### Prerequisites

- Ballerina Swan Lake (2201.10.0 or later)
- Docker & Docker Compose (for dependencies)
- Redis server
- Kafka server

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Medilink-v2
```

### 2. Install Dependencies

```bash
# Start infrastructure services
docker-compose up -d postgres redis kafka kafka-ui ocr-engine

# Install Ballerina dependencies
bal build
```

### 3. Configuration

Copy the environment file and configure:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# API Gateway Configuration
API_GATEWAY_HOST=0.0.0.0
API_GATEWAY_PORT=8080
LOG_LEVEL=INFO

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=medilink

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9094
KAFKA_CONSUMER_GROUP=api-gateway

# Service URLs
USER_SERVICE_URL=http://localhost:3001
APPOINTMENT_SERVICE_URL=http://localhost:3002
LAB_REPORT_SERVICE_URL=http://localhost:3100

# Rate Limiting
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### 4. Run the Application

```bash
# Development mode
bal run

# Production mode
bal build && java -jar target/bin/medilink-api_gateway.jar
```

## 🔗 API Endpoints

### Health Check

```
GET /api/health
```

Response:

```json
{
  "status": "OK",
  "service": "API Gateway",
  "timestamp": "2025-08-09T10:00:00Z"
}
```

### User Service Routes

```
GET|POST|PUT|DELETE /api/users/*
```

Routes to User Service at `USER_SERVICE_URL`

### Appointment Service Routes

```
GET|POST|PUT|DELETE /api/appointments/*
```

Routes to Appointment Service at `APPOINTMENT_SERVICE_URL`

### Lab Report Service Routes

```
GET|POST|PUT|DELETE /api/reports/*
```

Routes to Lab Report Service at `LAB_REPORT_SERVICE_URL`

## 📊 Rate Limiting

The API Gateway includes built-in rate limiting:

- **Window**: Configurable time window (default: 60 seconds)
- **Limit**: Maximum requests per window (default: 100)
- **Scope**: Per client IP address
- **Headers**: Response includes rate limit headers:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Time until rate limit resets

## 🔄 Service Communication

### Request Flow

1. Client sends request to API Gateway
2. Gateway applies rate limiting
3. Request is routed to appropriate service
4. Service response is returned to client
5. Audit logs are generated

### Error Handling

- **404**: Route not found
- **405**: Method not allowed
- **429**: Rate limit exceeded
- **502**: Service unavailable

## 📦 Package Details

### Redis Client Package

Located in `packages/redis-client/`

- Connection management
- Key-value operations
- TTL support
- Error handling

### Kafka Client Package

Located in `packages/kafka-client/`

- Producer for event publishing
- Consumer for event processing
- Topic management
- Error recovery

### Logger Package

Located in `packages/logger/`

- Multiple log levels (DEBUG, INFO, WARN, ERROR)
- Structured logging
- Configurable formatting
- Context support

## 🐳 Docker Integration

The project integrates with the existing Docker Compose setup:

```yaml
# From docker-compose.yml
services:
  postgres:
    image: bitnami/postgresql:17.4.0
    ports: ["5432:5432"]

  redis:
    image: redis/redis-stack:6.2.6-v19
    ports: ["6379:6379", "8001:8001"]

  kafka:
    image: bitnami/kafka:3.9.0
    ports: ["9094:9094"]

  ocr-engine:
    build: services/lab-report-service
    ports: ["3100:3100"]
```

## 🧪 Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8080/api/health

# Test user service routing
curl http://localhost:8080/api/users

# Test rate limiting
for i in {1..110}; do curl http://localhost:8080/api/health; done
```

### Rate Limit Testing

```bash
# Test rate limiting (should get 429 after 100 requests)
seq 1 110 | xargs -I {} curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/health
```

## 📈 Monitoring & Observability

### Metrics

- Request count per service
- Response times
- Error rates
- Rate limit violations

### Logging

- Structured JSON logs
- Request/response logging
- Error tracking
- Performance metrics

### Health Checks

- Gateway health endpoint
- Service connectivity checks
- Database connectivity
- Cache connectivity

## 🔒 Security Features

### Rate Limiting

- IP-based rate limiting
- Configurable windows and limits
- Redis-backed storage

### CORS

- Configurable allowed origins
- Method restrictions
- Header controls

### Input Validation

- Request validation
- Path parameter sanitization
- Header validation

## 🔧 Configuration Reference

### Environment Variables

| Variable                  | Description             | Default                 |
| ------------------------- | ----------------------- | ----------------------- |
| `API_GATEWAY_HOST`        | Gateway host address    | `0.0.0.0`               |
| `API_GATEWAY_PORT`        | Gateway port            | `8080`                  |
| `LOG_LEVEL`               | Logging level           | `INFO`                  |
| `REDIS_HOST`              | Redis server host       | `localhost`             |
| `REDIS_PORT`              | Redis server port       | `6379`                  |
| `REDIS_PASSWORD`          | Redis password          | `medilink`              |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka servers           | `localhost:9094`        |
| `KAFKA_CONSUMER_GROUP`    | Consumer group          | `api-gateway`           |
| `USER_SERVICE_URL`        | User service URL        | `http://localhost:3001` |
| `APPOINTMENT_SERVICE_URL` | Appointment service URL | `http://localhost:3002` |
| `LAB_REPORT_SERVICE_URL`  | Lab report service URL  | `http://localhost:3100` |
| `RATE_LIMIT_WINDOW`       | Rate limit window (ms)  | `60000`                 |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `100`                   |

## 🚀 Deployment

### Development

```bash
bal run
```

### Production

```bash
# Build the project
bal build

# Run the JAR file
java -jar target/bin/medilink-api_gateway.jar
```

### Docker Deployment

```dockerfile
FROM ballerina/ballerina:2201.10.0
COPY target/bin/medilink-api_gateway.jar /app/
WORKDIR /app
EXPOSE 8080
CMD ["java", "-jar", "medilink-api_gateway.jar"]
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

This project is part of the MediLink healthcare management system.

## 🆘 Troubleshooting

### Common Issues

1. **Port already in use**

   ```bash
   # Change the port in .env
   API_GATEWAY_PORT=8081
   ```

2. **Service connection failed**

   ```bash
   # Check service URLs in .env
   # Ensure target services are running
   ```

3. **Redis connection failed**

   ```bash
   # Start Redis with Docker
   docker-compose up -d redis
   ```

4. **Rate limiting not working**
   ```bash
   # Check Redis connectivity
   # Verify rate limit configuration
   ```

### Debug Mode

```bash
# Enable debug logging
LOG_LEVEL=DEBUG bal run
```

## 📚 Additional Resources

- [Ballerina Documentation](https://ballerina.io/learn/)
- [Ballerina HTTP Module](https://lib.ballerina.io/ballerina/http/)
- [Ballerina Redis Module](https://lib.ballerina.io/ballerina/redis/)
- [Ballerina Kafka Module](https://lib.ballerina.io/ballerina/kafka/)

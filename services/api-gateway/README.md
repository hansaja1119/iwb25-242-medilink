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

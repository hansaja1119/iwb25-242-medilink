# MediLink - Healthcare Management System

A comprehensive healthcare management system built with Ballerina, designed to streamline laboratory operations, patient management, and medical reporting in healthcare facilities.

## 🏥 System Overview

MediLink is a microservices-based healthcare platform that provides:

- **Laboratory Information Management System (LIMS)**
- **Patient Data Management**
- **Medical Report Processing**
- **Workflow Automation**
- **Real-time Analytics and Reporting**

## 🏗️ Architecture

The system follows a microservices architecture with an API Gateway managing all client requests:

```
Frontend Apps → API Gateway → Microservices
                     ↓
    ┌─────────────────────────────────────────┐
    │              API Gateway                │
    │         (Port: 3000)                    │
    │    • Rate Limiting                      │
    │    • CORS Support                       │
    │    • Service Routing                    │
    │    • Load Balancing                     │
    └─────────────────┬───────────────────────┘
                      │
         ┌────────────┼────────────┐
         ↓            ↓            ↓
    ┌─────────┐ ┌─────────┐ ┌─────────────┐
    │  User   │ │Medical  │ │Lab Report   │
    │Service  │ │Record   │ │Service      │
    │         │ │Service  │ │             │
    └─────────┘ └─────────┘ └─────────────┘
```

## 🚀 Features

### Core Platform Features

- **Microservices Architecture**: Scalable, maintainable service-oriented design
- **API Gateway**: Single entry point with intelligent routing and rate limiting
- **Real-time Processing**: Kafka-based event streaming
- **Caching**: Redis-based caching for performance optimization
- **Security**: Built-in authentication and authorization
- **Monitoring**: Comprehensive logging and health checks

### Laboratory Management

- 🔬 **Complete Lab Sample Lifecycle Management**
- 📊 **Automated Report Processing** using AI-powered Python parsers
- 📋 **Template-based Report Generation**
- 🔄 **Workflow Automation** for sample processing
- 📈 **Statistics and Analytics** endpoints
- 🔍 **Advanced Filtering and Search** capabilities
- 📄 **File Upload Support** for report processing (PDF, Images)

### Key Capabilities

- **Test Type Management**: Configure and manage laboratory test types
- **Sample Tracking**: Complete sample lifecycle from collection to reporting
- **Result Processing**: Automated extraction and validation of lab results
- **Report Generation**: Template-based report creation and finalization
- **Workflow Management**: Automated processing workflows
- **Data Analytics**: Real-time insights and operational statistics

## 📦 Services

### 1. API Gateway (`services/api-gateway/`)

**Port**: 3000

The central entry point for all client requests, providing:

- Service routing to microservices
- Rate limiting with Redis backend
- CORS support for web applications
- Health monitoring and error handling
- Load balancing and service discovery

**Key Features:**

- High-performance request routing
- Configurable rate limiting per client IP
- Comprehensive error handling
- Built-in health checks

### 2. Lab Report Service (`services/lab-report-service/`)

**Port**: 3004

Comprehensive laboratory information management system:

**Core Modules:**

- **Test Types**: Laboratory test configuration and management
- **Lab Samples**: Sample tracking and status management
- **Lab Results**: Result processing and review workflows
- **Lab Reports**: Report generation and finalization
- **Templates**: Report template management
- **Workflows**: Automated processing workflows

**Key Features:**

- AI-powered report processing using Python parsers
- File upload support (PDF, images)
- Template-based report generation
- Complete sample lifecycle management
- Real-time statistics and analytics

### 3. Shared Packages (`packages/`)

#### Redis Client (`packages/redis-client/`)

- Connection pooling and management
- Caching operations for performance optimization
- Session management support

#### Kafka Client (`packages/kafka-client/`)

- Event streaming and messaging
- Producer/consumer implementations
- Real-time data processing

#### Logger (`packages/logger/`)

- Structured logging across all services
- Multiple log levels and formats
- Centralized logging configuration

## 🛠️ Installation & Setup

### Prerequisites

- **Ballerina Swan Lake** (2201.8.0 or later)
- **MySQL/PostgreSQL** database
- **Redis** server
- **Apache Kafka** (optional, for event streaming)
- **Python 3.x** (for lab report processing)

### Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/hansaja1119/iwb25-242-medilink.git
   cd MediLink
   ```

2. **Install dependencies**

   ```bash
   # Build all packages
   cd packages/redis-client && bal build && cd ../..
   cd packages/kafka-client && bal build && cd ../..
   cd packages/logger && bal build && cd ../..
   ```

3. **Configure environment variables**

   ```bash
   # Database configuration
   export DB_HOST=localhost
   export DB_PORT=3306
   export DB_NAME=medilink
   export DB_USER=your_username
   export DB_PASSWORD=your_password

   # Redis configuration
   export REDIS_HOST=localhost
   export REDIS_PORT=6379
   ```

4. **Start the services**

   **Option A: Start all services individually**

   ```bash
   # Terminal 1: Start API Gateway
   cd services/api-gateway
   bal run

   # Terminal 2: Start Lab Report Service
   cd services/lab-report-service
   bal run
   ```

   **Option B: Start specific service**

   ```bash
   # Start only Lab Report Service
   cd services/lab-report-service
   bal run
   ```

5. **Verify installation**

   ```bash
   # Check API Gateway health
   curl http://localhost:3000/health

   # Check Lab Report Service health
   curl http://localhost:3004/health
   ```

**MediLink** - Transforming Healthcare Through Technology

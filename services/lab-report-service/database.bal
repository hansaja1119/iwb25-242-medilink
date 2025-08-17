import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

# Database connection pool
postgresql:Client? dbClient = ();

# Initialize database connection
# + return - Error if connection fails
public function initDatabase() returns error? {
    log:printInfo("Initializing database connection...");

    postgresql:Client|sql:Error dbResult = new (
        host = "localhost",
        port = 5432,
        database = "medilink",
        username = "admin",
        password = "medilink",
        connectionPool = {
            maxOpenConnections: 10,
            maxConnectionLifeTime: 900,
            minIdleConnections: 1
        }
    );

    if dbResult is sql:Error {
        log:printError("Failed to connect to database", dbResult);
        log:printError("Please ensure PostgreSQL is running and the database 'medilink' exists");
        log:printError("You can create the database with: CREATE DATABASE medilink;");
        return dbResult;
    }

    dbClient = dbResult;
    log:printInfo("Database connection established successfully");

    // Create tables if they don't exist
    error? tableResult = createTables();
    if tableResult is error {
        log:printError("Failed to create database tables", tableResult);
        return tableResult;
    }

    return;
}

# Get database client
# + return - Database client or error
public function getDbClient() returns postgresql:Client|error {
    postgresql:Client? dbClientInstance = dbClient;
    if dbClientInstance is postgresql:Client {
        return dbClientInstance;
    }
    return error("Database client not initialized");
}

# Create database tables
# + return - Error if table creation fails
function createTables() returns error? {
    postgresql:Client|error clientResult = getDbClient();
    if clientResult is error {
        return clientResult;
    }
    postgresql:Client dbClientInstance = clientResult;

    // Create test_types table (matching TestTypes entity)
    sql:ExecutionResult|sql:Error result1 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS test_types (
            id SERIAL PRIMARY KEY,
            value VARCHAR(255) NOT NULL,
            label VARCHAR(255) NOT NULL,
            category VARCHAR(100) NOT NULL,
            parser_class VARCHAR(255),
            parser_module VARCHAR(255),
            report_fields TEXT,
            reference_ranges TEXT,
            basic_fields TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
    );

    if result1 is sql:Error {
        log:printError("Failed to create test_types table", result1);
        return result1;
    }

    // Create lab_samples table (matching LabSample entity)
    sql:ExecutionResult|sql:Error result2 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS lab_samples (
            id SERIAL PRIMARY KEY,
            labId VARCHAR(255) NOT NULL,
            barcode VARCHAR(255) NOT NULL,
            testTypeId INTEGER NOT NULL,
            sampleType VARCHAR(100) NOT NULL,
            volume VARCHAR(50),
            container VARCHAR(100),
            patientId VARCHAR(255) NOT NULL,
            createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expectedTime TIMESTAMP,
            updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'pending',
            priority VARCHAR(50) DEFAULT 'normal',
            notes TEXT,
            FOREIGN KEY (testTypeId) REFERENCES test_types(id)
        )`
    );

    if result2 is sql:Error {
        log:printError("Failed to create lab_samples table", result2);
        return result2;
    }

    // Create lab_results table (matching LabResult entity)
    sql:ExecutionResult|sql:Error result3 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS lab_results (
            id SERIAL PRIMARY KEY,
            labSampleId INTEGER NOT NULL,
            reportUrl VARCHAR(500),
            extractedData TEXT,
            createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'processed',
            FOREIGN KEY (labSampleId) REFERENCES lab_samples(id)
        )`
    );

    if result3 is sql:Error {
        log:printError("Failed to create lab_results table", result3);
        return result3;
    }

    // Create templates table
    sql:ExecutionResult|sql:Error result4 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS templates (
            id VARCHAR(255) PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            content JSONB NOT NULL,
            supported_test_types TEXT[],
            version VARCHAR(50) DEFAULT '1.0',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
    );

    if result4 is sql:Error {
        log:printError("Failed to create templates table", result4);
        return result4;
    }

    // Create workflow_status table
    sql:ExecutionResult|sql:Error result5 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS workflow_status (
            id VARCHAR(255) PRIMARY KEY,
            status VARCHAR(50) NOT NULL,
            sample_id VARCHAR(255) NOT NULL,
            steps JSONB,
            start_time TIMESTAMP NOT NULL,
            end_time TIMESTAMP,
            error_message TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
    );

    if result5 is sql:Error {
        log:printError("Failed to create workflow_status table", result5);
        return result5;
    }

    log:printInfo("All database tables created successfully");
    return;
}

# Close database connection
# + return - Error if database close operation fails, otherwise nil
public function closeDatabase() returns error? {
    postgresql:Client? dbClientInstance = dbClient;
    if dbClientInstance is postgresql:Client {
        check dbClientInstance.close();
        log:printInfo("Database connection closed");
    }
    return;
}

import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

# Database connection pool
postgresql:Client? dbClient = ();

# Initialize database connection
# + return - Error if connection fails
public function initDatabase() returns error? {
    postgresql:Client|sql:Error dbResult = new (
        host = "localhost",
        port = 5432,
        database = "medilink",
        username = "admin",
        password = "medilink"
    );

    if dbResult is sql:Error {
        log:printError("Failed to connect to database", dbResult);
        return dbResult;
    }

    dbClient = dbResult;
    log:printInfo("Database connection established successfully");

    // Create tables if they don't exist
    return createTables();
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

    // Create test_types table
    sql:ExecutionResult|sql:Error result1 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS test_types (
            id VARCHAR(255) PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            category VARCHAR(100),
            parser_config JSONB,
            reference_ranges JSONB,
            units VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
    );

    if result1 is sql:Error {
        log:printError("Failed to create test_types table", result1);
        return result1;
    }

    // Create lab_samples table
    sql:ExecutionResult|sql:Error result2 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS lab_samples (
            id VARCHAR(255) PRIMARY KEY,
            patient_id VARCHAR(255) NOT NULL,
            sample_type VARCHAR(100) NOT NULL,
            collection_date TIMESTAMP NOT NULL,
            status VARCHAR(50) DEFAULT 'collected',
            barcode VARCHAR(255),
            collection_site VARCHAR(255),
            handling_instructions TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )`
    );

    if result2 is sql:Error {
        log:printError("Failed to create lab_samples table", result2);
        return result2;
    }

    // Create lab_results table
    sql:ExecutionResult|sql:Error result3 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS lab_results (
            id VARCHAR(255) PRIMARY KEY,
            sample_id VARCHAR(255) NOT NULL,
            test_type_id VARCHAR(255) NOT NULL,
            result_value TEXT NOT NULL,
            units VARCHAR(50),
            reference_range VARCHAR(255),
            status VARCHAR(50) DEFAULT 'normal',
            comments TEXT,
            interpretation TEXT,
            technician VARCHAR(255),
            result_date TIMESTAMP NOT NULL,
            is_encrypted BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

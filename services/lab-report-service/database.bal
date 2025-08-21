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
        `CREATE TABLE IF NOT EXISTS lab_sample (
            id SERIAL PRIMARY KEY,
            lab_id VARCHAR(255) NOT NULL,
            barcode VARCHAR(255) NOT NULL,
            test_type_id INTEGER NOT NULL,
            sample_type VARCHAR(100) NOT NULL,
            volume VARCHAR(50),
            container VARCHAR(100),
            patient_id VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expected_time TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'pending',
            priority VARCHAR(50) DEFAULT 'normal',
            notes TEXT,
            FOREIGN KEY (test_type_id) REFERENCES test_types(id)
        )`
    );

    if result2 is sql:Error {
        log:printError("Failed to create lab_sample table", result2);
        return result2;
    }

    // Create lab_results table (matching LabResult entity)
    sql:ExecutionResult|sql:Error result3 = dbClientInstance->execute(
        `CREATE TABLE IF NOT EXISTS lab_result (
            id SERIAL PRIMARY KEY,
            "labSampleId" INTEGER NOT NULL,
            "reportUrl" VARCHAR(500),
            "extractedData" TEXT,
            "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(50) DEFAULT 'processed',
            FOREIGN KEY ("labSampleId") REFERENCES lab_sample(id)
        )`
    );

    if result3 is sql:Error {
        log:printError("Failed to create lab_result table", result3);
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

    // Insert initial test data
    error? dataResult = insertInitialData();
    if dataResult is error {
        log:printError("Failed to insert initial data", dataResult);
        return dataResult;
    }

    return;
}

# Insert initial test data
# + return - Error if data insertion fails
function insertInitialData() returns error? {
    postgresql:Client|error clientResult = getDbClient();
    if clientResult is error {
        return clientResult;
    }
    postgresql:Client dbClientInstance = clientResult;

    // Insert test types if they don't exist
    sql:ExecutionResult|sql:Error testTypeResult = dbClientInstance->execute(`
        INSERT INTO test_types (id, value, label, category, parser_class, parser_module) 
        VALUES 
            (1, 'fbc', 'Full Blood Count', 'hematology', 'FBCReportParser', 'parser_fbc_report'),
            (2, 'lipid', 'Lipid Profile', 'biochemistry', 'LabReportParser', 'parser_lab_report'),
            (3, 'thyroid', 'Thyroid Function', 'endocrinology', 'LabReportParser', 'parser_lab_report')
        ON CONFLICT (id) DO NOTHING
    `);

    if testTypeResult is sql:Error {
        log:printError("Failed to insert test types", testTypeResult);
        return testTypeResult;
    }

    // Insert sample test data if no samples exist
    record {int count;}|sql:Error sampleCountResult = dbClientInstance->queryRow(`SELECT COUNT(*) as count FROM lab_sample`);
    int sampleCount = sampleCountResult is record {int count;} ? sampleCountResult.count : 0;

    if sampleCount == 0 {
        sql:ExecutionResult|sql:Error sampleResult = dbClientInstance->execute(`
            INSERT INTO lab_sample (id, lab_id, barcode, test_type_id, sample_type, volume, container, patient_id, status, priority) 
            VALUES 
                (1, 'LAB001', 'BC001', 1, 'blood', '5ml', 'EDTA tube', 'P001', 'pending', 'normal'),
                (2, 'LAB002', 'BC002', 2, 'serum', '3ml', 'SST tube', 'P002', 'pending', 'normal'),
                (3, 'LAB003', 'BC003', 3, 'serum', '2ml', 'SST tube', 'P003', 'pending', 'normal'),
                (8, 'LAB008', 'BC008', 1, 'blood', '5ml', 'EDTA tube', 'P008', 'pending', 'normal')
            ON CONFLICT (id) DO NOTHING
        `);

        if sampleResult is sql:Error {
            log:printError("Failed to insert sample data", sampleResult);
            return sampleResult;
        }

        log:printInfo("Initial test data inserted successfully");
    } else {
        log:printInfo("Sample data already exists, skipping initial data insertion");
    }

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

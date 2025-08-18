import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;

# Test Type Service for managing test types
public class TestTypeService {

    # Create a new test type
    # + testTypeData - Test type creation data
    # + return - Created test type or error
    public function createTestType(TestTypeCreate testTypeData) returns TestType|error {
        postgresql:Client dbClient = check getDbClient();

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO test_types (value, label, category, parser_class, parser_module, reference_ranges, report_fields)
            VALUES (${testTypeData.value}, ${testTypeData.label}, ${testTypeData.category}, 
                    ${testTypeData?.parserClass}, ${testTypeData?.parserModule}, ${testTypeData?.referenceRanges.toJsonString()}, ${testTypeData?.reportFields.toJsonString()})
        `);

        if result is sql:Error {
            log:printError("Failed to create test type", result);
            return error("Failed to create test type: " + result.message());
        }

        // Get the generated ID and return the full TestType
        int|string? generatedId = result.lastInsertId;
        if generatedId is int {
            log:printInfo("Test type created with ID: " + generatedId.toString());
            return self.getTestTypeById(generatedId.toString());
        } else {
            return error("Failed to get generated test type ID");
        }
    }

    # Get all test types
    # + return - Array of test types or error
    public function getAllTestTypes() returns TestType[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<TestTypeRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM test_types ORDER BY id
        `);

        TestType[] testTypes = [];
        check from TestTypeRecord testTypeRecord in resultStream
            do {
                testTypes.push({
                    id: testTypeRecord.id,
                    value: testTypeRecord.value,
                    label: testTypeRecord.label,
                    category: testTypeRecord.category,
                    parserClass: testTypeRecord.parser_class,
                    parserModule: testTypeRecord.parser_module,
                    reportFields: testTypeRecord.report_fields,
                    referenceRanges: testTypeRecord.reference_ranges,
                    basicFields: testTypeRecord.basic_fields,
                    createdAt: testTypeRecord.created_at,
                    updatedAt: testTypeRecord.updated_at
                });
            };

        check resultStream.close();
        return testTypes;
    }

    # Get test type by ID
    # + id - Test type ID
    # + return - Test type or error
    public function getTestTypeById(string id) returns TestType|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(id);
        if idInt is error {
            return error("Invalid test type ID format");
        }

        TestTypeRecord|sql:Error result = dbClient->queryRow(`
            SELECT * FROM test_types WHERE id = ${idInt}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                return error("Test type not found");
            }
            return error("Failed to get test type: " + result.message());
        }

        return {
            id: result.id,
            value: result.value,
            label: result.label,
            category: result.category,
            parserClass: result.parser_class,
            parserModule: result.parser_module,
            reportFields: result.report_fields,
            referenceRanges: result.reference_ranges,
            basicFields: result.basic_fields,
            createdAt: result.created_at,
            updatedAt: result.updated_at
        };
    }

    # Update test type
    # + id - Test type ID
    # + updateData - Updated test type data
    # + return - Updated test type or error
    public function updateTestType(string id, TestTypeUpdate updateData) returns TestType|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(id);
        if idInt is error {
            return error("Invalid test type ID format");
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE test_types 
            SET value = COALESCE(${updateData?.value}, value), 
                label = COALESCE(${updateData?.label}, label),
                category = COALESCE(${updateData?.category}, category), 
                parser_class = COALESCE(${updateData?.parserClass}, parser_class), 
                parser_module = COALESCE(${updateData?.parserModule}, parser_module), 
                reference_ranges = COALESCE(${updateData?.referenceRanges.toJsonString()}, reference_ranges),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to update test type: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Test type not found");
        }

        log:printInfo("Test type updated: " + id);
        return check self.getTestTypeById(id);
    }

    # Delete test type
    # + id - Test type ID
    # + return - Error if deletion fails
    public function deleteTestType(string id) returns error? {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(id);
        if idInt is error {
            return error("Invalid test type ID format");
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            DELETE FROM test_types WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to delete test type: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Test type not found");
        }

        log:printInfo("Test type deleted: " + id);
        return;
    }
}

# Database record type for test types (matching exact database schema)

# Global test type service instance
public final TestTypeService testTypeService = new;

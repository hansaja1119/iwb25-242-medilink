import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/postgresql;

# Test Type Service for managing test types
public class TestTypeService {

    # Create a new test type
    # + testType - Test type data
    # + return - Created test type or error
    public function createTestType(TestType testType) returns TestType|error {
        postgresql:Client dbClient = check getDbClient();

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO test_types (id, name, description, category, parser_config, reference_ranges, units)
            VALUES (${testType.id}, ${testType.name}, ${testType.description}, ${testType.category}, 
                    ${testType?.parserConfig.toJsonString()}, ${testType?.referenceRanges.toJsonString()}, ${testType?.units})
        `);

        if result is sql:Error {
            log:printError("Failed to create test type", result);
            return error("Failed to create test type: " + result.message());
        }

        log:printInfo("Test type created: " + testType.id);
        return testType;
    }

    # Get all test types
    # + return - Array of test types or error
    public function getAllTestTypes() returns TestType[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<TestTypeRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT id, name, description, category, parser_config, reference_ranges, units, 
                   created_at, updated_at FROM test_types ORDER BY name
        `);

        TestType[] testTypes = [];
        check from TestTypeRecord testTypeRecord in resultStream
            do {
                testTypes.push({
                    id: testTypeRecord.id,
                    name: testTypeRecord.name,
                    description: testTypeRecord.description ?: "",
                    category: testTypeRecord.category ?: "",
                    parserConfig: testTypeRecord.parser_config,
                    referenceRanges: testTypeRecord.reference_ranges,
                    units: testTypeRecord.units,
                    createdAt: testTypeRecord.created_at.toString(),
                    updatedAt: testTypeRecord.updated_at.toString()
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

        TestTypeRecord|sql:Error result = dbClient->queryRow(`
            SELECT id, name, description, category, parser_config, reference_ranges, units, 
                   created_at, updated_at FROM test_types WHERE id = ${id}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                return error("Test type not found");
            }
            return error("Failed to get test type: " + result.message());
        }

        return {
            id: result.id,
            name: result.name,
            description: result.description ?: "",
            category: result.category ?: "",
            parserConfig: result.parser_config,
            referenceRanges: result.reference_ranges,
            units: result.units,
            createdAt: result.created_at.toString(),
            updatedAt: result.updated_at.toString()
        };
    }

    # Update test type
    # + id - Test type ID
    # + testType - Updated test type data
    # + return - Updated test type or error
    public function updateTestType(string id, TestType testType) returns TestType|error {
        postgresql:Client dbClient = check getDbClient();

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE test_types 
            SET name = ${testType.name}, description = ${testType.description}, 
                category = ${testType.category}, parser_config = ${testType?.parserConfig.toJsonString()}, 
                reference_ranges = ${testType?.referenceRanges.toJsonString()}, units = ${testType?.units},
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ${id}
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

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            DELETE FROM test_types WHERE id = ${id}
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

# Database record type for test types
type TestTypeRecord record {|
    string id;
    string name;
    string? description;
    string? category;
    json? parser_config;
    json? reference_ranges;
    string? units;
    time:Civil created_at;
    time:Civil updated_at;
|};

# Global test type service instance
public final TestTypeService testTypeService = new;

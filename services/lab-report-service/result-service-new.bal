import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/postgresql;

# Lab Result Service for managing lab results and reports
public class LabResultService {

    # Create a new lab result
    # + resultData - Result data without ID
    # + return - Created result or error
    public function createResult(LabResultCreate resultData) returns FullLabResult|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert sampleId string to integer for database
        int|error sampleIdInt = int:fromString(resultData.sampleId);
        if sampleIdInt is error {
            return error("Invalid sample ID format");
        }

        // Insert into database
        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO lab_result (lab_sample_id, status, extracted_data)
            VALUES (${sampleIdInt}, 'pending_review', ${resultData.results.toJsonString()})
            RETURNING id
        `);

        if result is sql:Error {
            log:printError("Failed to create lab result", result);
            return error("Failed to create lab result: " + result.message());
        }

        // Get the generated ID
        string generatedId = "";
        if result.generatedKeys != () {
            record {}[] keys = result.generatedKeys ?: [];
            if keys.length() > 0 {
                record {} firstKey = keys[0];
                if firstKey.hasKey("id") {
                    var idValue = firstKey["id"];
                    generatedId = idValue is int ? idValue.toString() : idValue.toString();
                }
            }
        }

        string timestamp = time:utcToString(time:utcNow());
        FullLabResult labResult = {
            id: generatedId,
            sampleId: resultData.sampleId,
            status: "pending_review",
            results: resultData.results,
            reportUrl: resultData.reportUrl ?: "",
            reviewedBy: "",
            reviewNotes: "",
            createdAt: timestamp,
            updatedAt: timestamp
        };

        log:printInfo("Lab result created with ID: " + generatedId + " for sample: " + resultData.sampleId);
        return labResult;
    }

    # Get result by ID
    # + resultId - Result ID
    # + return - Result or error
    public function getResult(string resultId) returns FullLabResult|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(resultId);
        if idInt is error {
            return error("Invalid result ID format");
        }

        LabResultRecord|sql:Error result = dbClient->queryRow(`
            SELECT * FROM lab_result WHERE id = ${idInt}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                return error("Lab result not found");
            }
            return error("Failed to get lab result: " + result.message());
        }

        return self.convertToFullLabResult(result);
    }

    # Get results by sample ID
    # + sampleId - Sample ID
    # + return - Array of results
    public function getResultsBySampleId(string sampleId) returns FullLabResult[]|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error sampleIdInt = int:fromString(sampleId);
        if sampleIdInt is error {
            return error("Invalid sample ID format");
        }

        stream<LabResultRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_result WHERE lab_sample_id = ${sampleIdInt} ORDER BY created_at DESC
        `);

        FullLabResult[] results = [];
        check from LabResultRecord labResultRecord in resultStream
            do {
                results.push(self.convertToFullLabResult(labResultRecord));
            };

        check resultStream.close();
        return results;
    }

    # Update result
    # + resultId - Result ID
    # + updateData - Update data
    # + return - Updated result or error
    public function updateResult(string resultId, LabResultUpdate updateData) returns FullLabResult|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(resultId);
        if idInt is error {
            return error("Invalid result ID format");
        }

        // Handle optional results conversion
        string? resultsJson = updateData?.results is json ? updateData?.results.toJsonString() : ();

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE lab_result 
            SET status = COALESCE(${updateData?.status}, status),
                extracted_data = COALESCE(${resultsJson}, extracted_data)
            WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to update lab result: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Lab result not found");
        }

        log:printInfo("Lab result updated: " + resultId);
        return check self.getResult(resultId);
    }

    # Review and approve result
    # + resultId - Result ID
    # + reviewedBy - Reviewer name
    # + notes - Review notes
    # + return - Updated result or error
    public function reviewResult(string resultId, string reviewedBy, string? notes = ()) returns FullLabResult|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(resultId);
        if idInt is error {
            return error("Invalid result ID format");
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE lab_result 
            SET status = 'reviewed'
            WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to review lab result: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Lab result not found");
        }

        log:printInfo("Lab result reviewed: " + resultId + " by " + reviewedBy);
        return check self.getResult(resultId);
    }

    # Get all results
    # + return - Array of all results
    public function getAllResults() returns FullLabResult[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<LabResultRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_result ORDER BY created_at DESC
        `);

        FullLabResult[] results = [];
        check from LabResultRecord labResultRecord in resultStream
            do {
                results.push(self.convertToFullLabResult(labResultRecord));
            };

        check resultStream.close();
        return results;
    }

    # Get results by status
    # + status - Result status
    # + return - Array of results
    public function getResultsByStatus(string status) returns FullLabResult[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<LabResultRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_result WHERE status = ${status} ORDER BY created_at DESC
        `);

        FullLabResult[] results = [];
        check from LabResultRecord labResultRecord in resultStream
            do {
                results.push(self.convertToFullLabResult(labResultRecord));
            };

        check resultStream.close();
        return results;
    }

    # Convert database record to full lab result
    # + dbRecord - Database record
    # + return - Full lab result
    public function convertToFullLabResult(LabResultRecord dbRecord) returns FullLabResult {
        json extractedData = {};
        string timestamp = time:utcToString(time:utcNow());

        // Parse extracted_data if it exists
        if dbRecord.extracted_data is string {
            json|error parsedData = (<string>dbRecord.extracted_data).fromJsonString();
            if parsedData is json {
                extractedData = parsedData;
            }
        }

        string createdAtStr = timestamp;
        if dbRecord.created_at is time:Civil {
            time:Utc|time:Error utcResult = time:utcFromCivil(<time:Civil>dbRecord.created_at);
            if utcResult is time:Utc {
                createdAtStr = time:utcToString(utcResult);
            }
        }

        return {
            id: dbRecord.id is int ? dbRecord.id.toString() : "",
            sampleId: dbRecord.lab_sample_id.toString(),
            status: dbRecord.status ?: "unknown",
            results: extractedData,
            reportUrl: dbRecord.report_url ?: "",
            reviewedBy: "",
            reviewNotes: "",
            createdAt: createdAtStr,
            updatedAt: createdAtStr
        };
    }

    # Generate mock analysis (placeholder)
    # + resultData - Result data
    # + return - Analysis results
    public function generateAnalysis(json resultData) returns json {
        return {
            "status": "completed",
            "analysis": {
                "findings": [
                    "All values within normal range",
                    "No abnormal patterns detected"
                ],
                "flaggedValues": [],
                "recommendations": []
            }
        };
    }

    # Get result statistics
    # + return - Result statistics
    public function getResultStats() returns json|error {
        postgresql:Client dbClient = check getDbClient();

        // Get total count
        record {int count;}|sql:Error totalResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result`);
        int totalResults = totalResult is record {int count;} ? totalResult.count : 0;

        // Get count by status
        record {int count;}|sql:Error pendingResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result WHERE status = 'pending_review'`);
        int pendingReview = pendingResult is record {int count;} ? pendingResult.count : 0;

        record {int count;}|sql:Error reviewedResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result WHERE status = 'reviewed'`);
        int reviewed = reviewedResult is record {int count;} ? reviewedResult.count : 0;

        record {int count;}|sql:Error flaggedResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result WHERE status = 'flagged'`);
        int flagged = flaggedResult is record {int count;} ? flaggedResult.count : 0;

        return {
            "totalResults": totalResults,
            "pendingReview": pendingReview,
            "reviewed": reviewed,
            "flagged": flagged,
            "totalReports": 0, // Reports not implemented in DB yet
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global lab result service instance
public final LabResultService labResultService = new;

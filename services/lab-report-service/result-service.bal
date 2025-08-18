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
            INSERT INTO lab_result (labSampleId, status, extractedData)
            VALUES (${sampleIdInt}, 'pending_review', ${resultData.results.toJsonString()})
            RETURNING id
        `);

        if result is sql:Error {
            log:printError("Failed to create lab result", result);
            return error("Failed to create lab result: " + result.message());
        }

        // Get the generated ID
        string generatedId;
        int|string? lastId = result.lastInsertId;
        if lastId is string {
            generatedId = lastId;
        } else if lastId is int {
            generatedId = lastId.toString();
        } else {
            return error("Failed to get generated lab result ID");
        }

        string timestamp = time:utcToString(time:utcNow());

        // Return the created result in FullLabResult format
        FullLabResult labResult = {
            id: generatedId,
            sampleId: resultData.sampleId,
            testTypeId: resultData.testTypeId,
            results: resultData.results,
            normalRanges: resultData?.normalRanges,
            status: "pending_review",
            reviewedBy: resultData?.reviewedBy,
            reviewedAt: (),
            completedAt: (),
            notes: resultData?.notes,
            resultDate: resultData?.resultDate,
            resultValue: resultData?.resultValue,
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

        // Convert database record to FullLabResult
        return self.convertToFullLabResult(result);
    }

    # Get results by sample ID
    # + sampleId - Sample ID
    # + return - Array of results
    public function getResultsBySample(string sampleId) returns FullLabResult[]|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error sampleIdInt = int:fromString(sampleId);
        if sampleIdInt is error {
            return error("Invalid sample ID format");
        }

        stream<LabResultRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_result WHERE labSampleId = ${sampleIdInt} ORDER BY "createdAt DESC
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
                extractedData = COALESCE(${resultsJson}, extractedData)
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
            SELECT * FROM lab_result ORDER BY "createdAt" DESC
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
            SELECT * FROM lab_result WHERE status = ${status} ORDER BY "createdAt" DESC
        `);

        FullLabResult[] results = [];
        check from LabResultRecord labResultRecord in resultStream
            do {
                results.push(self.convertToFullLabResult(labResultRecord));
            };

        check resultStream.close();
        return results;
    }

    # Convert database record to FullLabResult
    # + dbRecord - Database record
    # + return - FullLabResult
    private function convertToFullLabResult(LabResultRecord dbRecord) returns FullLabResult {
        string timestamp = time:utcToString(time:utcNow());
        json extractedData = {};

        // Parse extractedData if it exists
        if dbRecord.extractedData is string {
            json|error parsedData = (<string>dbRecord.extractedData).fromJsonString();
            if parsedData is json {
                extractedData = parsedData;
            }
        }

        string createdAtStr = timestamp;
        if dbRecord.createdAt is time:Civil {
            time:Utc|time:Error utcResult = time:utcFromCivil(<time:Civil>dbRecord.createdAt);
            if utcResult is time:Utc {
                createdAtStr = time:utcToString(utcResult);
            }
        }

        return {
            id: dbRecord.id is int ? dbRecord.id.toString() : "",
            sampleId: dbRecord.labSampleId.toString(),
            testTypeId: "1", // Default value, can be enhanced later
            results: extractedData,
            normalRanges: (),
            status: dbRecord.status,
            reviewedBy: (),
            reviewedAt: (),
            completedAt: (),
            notes: (),
            resultDate: (),
            resultValue: (),
            createdAt: createdAtStr,
            updatedAt: timestamp
        };
    }

    # Generate lab report from results
    # + sampleId - Sample ID
    # + templateId - Template ID
    # + generatedBy - Who generated the report
    # + return - Generated report or error
    public function generateReport(string sampleId, string? templateId = (), string? generatedBy = ()) returns LabReport|error {
        // Get all results for the sample
        FullLabResult[] sampleResults = check self.getResultsBySample(sampleId);

        if sampleResults.length() == 0 {
            return error("No results found for sample");
        }

        // Check if all results are reviewed
        foreach FullLabResult result in sampleResults {
            if result.status != "reviewed" {
                return error("All results must be reviewed before generating report");
            }
        }

        string timestamp = time:utcToString(time:utcNow());

        // Generate report summary
        json reportSummary = self.generateReportSummary(sampleResults);

        LabReport report = {
            id: sampleId + "_report_" + timestamp,
            sampleId: sampleId,
            templateId: templateId,
            content: reportSummary,
            status: "draft",
            generatedBy: generatedBy ?: "System",
            generatedAt: timestamp,
            finalizedBy: (),
            finalizedAt: (),
            createdAt: timestamp,
            updatedAt: timestamp
        };

        log:printInfo("Lab report generated for sample: " + sampleId);
        return report;
    }

    # Get report by ID (mock implementation for now)
    # + reportId - Report ID
    # + return - Report or error
    public function getReport(string reportId) returns LabReport|error {
        return error("Report not found - reports are not persisted in database yet");
    }

    # Get reports by sample ID (mock implementation for now)
    # + sampleId - Sample ID
    # + return - Array of reports
    public function getReportsBySample(string sampleId) returns LabReport[]|error {
        return []; // Return empty array for now
    }

    # Get all reports (mock implementation for now)
    # + return - Array of all reports
    public function getAllReports() returns LabReport[]|error {
        return []; // Return empty array for now
    }

    # Finalize report (mock implementation for now)
    # + reportId - Report ID
    # + finalizedBy - Who finalized the report
    # + return - Updated report or error
    public function finalizeReport(string reportId, string finalizedBy) returns LabReport|error {
        return error("Report finalization not implemented yet");
    }

    # Generate report summary from results
    # + results - Array of lab results
    # + return - Report summary JSON
    private function generateReportSummary(FullLabResult[] results) returns json {
        json[] resultSummaries = [];

        foreach FullLabResult result in results {
            json resultSummary = {
                "resultId": result.id,
                "testTypeId": result.testTypeId,
                "results": result.results,
                "normalRanges": result?.normalRanges,
                "status": result.status,
                "reviewedBy": result?.reviewedBy,
                "reviewedAt": result?.reviewedAt,
                "notes": result?.notes
            };

            resultSummaries.push(resultSummary);
        }

        return {
            "summary": {
                "totalTests": results.length(),
                "allTestsCompleted": true,
                "reportGeneratedAt": time:utcToString(time:utcNow())
            },
            "results": resultSummaries,
            "interpretation": {
                "overallStatus": "completed",
                "criticalValues": [],
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

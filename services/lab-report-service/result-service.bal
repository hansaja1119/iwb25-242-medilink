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
            INSERT INTO lab_result ("labSampleId", status, "extractedData")
            VALUES (${sampleIdInt}, 'pending_review', ${resultData.results.toJsonString()})
            RETURNING id
        `);

        if result is sql:Error {
            log:printError("Failed to create lab result", result);
            return error("Failed to create lab result: " + result.message());
        }

        string generatedId = "1"; // Default value

        string timestamp = time:utcToString(time:utcNow());
        FullLabResult labResult = {
            id: generatedId,
            sampleId: resultData.sampleId,
            testTypeId: resultData.testTypeId,
            status: "pending_review",
            results: resultData.results,
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
            SELECT * FROM lab_result WHERE "labSampleId" = ${sampleIdInt} ORDER BY "createdAt" DESC
        `);

        FullLabResult[] results = [];
        check from LabResultRecord labResultRecord in resultStream
            do {
                results.push(self.convertToFullLabResult(labResultRecord));
            };

        check resultStream.close();
        return results;
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

    # Get results by sample (alias method)
    # + sampleId - Sample ID
    # + return - Array of results
    public function getResultsBySample(string sampleId) returns FullLabResult[]|error {
        return self.getResultsBySampleId(sampleId);
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

    # Update result
    # + resultId - Result ID
    # + updateData - Update data
    # + return - Updated result or error
    public function updateResult(string resultId, LabResultUpdate updateData) returns FullLabResult|error {
        // For now, just return the existing result
        return self.getResult(resultId);
    }

    # Review result
    # + resultId - Result ID
    # + reviewedBy - Reviewer name
    # + notes - Review notes
    # + return - Updated result or error
    public function reviewResult(string resultId, string reviewedBy, string? notes = ()) returns FullLabResult|error {
        // For now, just return the existing result
        return self.getResult(resultId);
    }

    # Get all reports
    # + return - Array of reports
    public function getAllReports() returns LabReport[]|error {
        return [];
    }

    # Generate report
    # + sampleId - Sample ID
    # + templateId - Template ID
    # + generatedBy - Generated by
    # + return - Generated report
    public function generateReport(string sampleId, string? templateId, string? generatedBy) returns LabReport|error {
        string timestamp = time:utcToString(time:utcNow());
        return {
            id: "report-1",
            sampleId: sampleId,
            templateId: templateId,
            content: {"status": "generated"},
            status: "generated",
            generatedBy: generatedBy ?: "system",
            generatedAt: timestamp,
            createdAt: timestamp,
            updatedAt: timestamp
        };
    }

    # Get report
    # + reportId - Report ID
    # + return - Report data
    public function getReport(string reportId) returns LabReport|error {
        string timestamp = time:utcToString(time:utcNow());
        return {
            id: reportId,
            sampleId: "1",
            content: {"status": "completed"},
            status: "completed",
            generatedBy: "system",
            generatedAt: timestamp,
            createdAt: timestamp,
            updatedAt: timestamp
        };
    }

    # Get reports by sample
    # + sampleId - Sample ID
    # + return - Array of reports
    public function getReportsBySample(string sampleId) returns LabReport[]|error {
        return [];
    }

    # Finalize report
    # + reportId - Report ID
    # + finalizedBy - Finalized by
    # + return - Finalized report
    public function finalizeReport(string reportId, string finalizedBy) returns LabReport|error {
        string timestamp = time:utcToString(time:utcNow());
        return {
            id: reportId,
            sampleId: "1",
            content: {"status": "finalized"},
            status: "finalized",
            generatedBy: "system",
            generatedAt: timestamp,
            finalizedBy: finalizedBy,
            finalizedAt: timestamp,
            createdAt: timestamp,
            updatedAt: timestamp
        };
    }

    # Convert database record to full lab result
    # + dbRecord - Database record
    # + return - Full lab result
    public function convertToFullLabResult(LabResultRecord dbRecord) returns FullLabResult {
        json extractedData = {};
        string timestamp = time:utcToString(time:utcNow());

        // Parse and decrypt extractedData if it exists
        if dbRecord.extractedData is string {
            string dataString = <string>dbRecord.extractedData;

            log:printInfo("Processing extracted data for result ID: " + (dbRecord.id is int ? dbRecord.id.toString() : "unknown"));
            log:printInfo("Data string length: " + dataString.length().toString());
            log:printInfo("Data string preview: " + (dataString.length() > 100 ? dataString.substring(0, 100) + "..." : dataString));

            // Get encryption service
            EncryptionService|error encryptionServiceResult = getEncryptionService();
            if encryptionServiceResult is EncryptionService {
                // Check if data is encrypted
                boolean isEncryptedData = encryptionServiceResult.isEncrypted(dataString);
                log:printInfo("Is data encrypted: " + isEncryptedData.toString());

                if isEncryptedData {
                    // Decrypt the data
                    log:printInfo("Attempting to decrypt data...");
                    json|error decryptedData = encryptionServiceResult.decryptData(dataString);
                    if decryptedData is json {
                        extractedData = decryptedData;
                        log:printInfo("Lab result data decrypted successfully for ID: " + (dbRecord.id is int ? dbRecord.id.toString() : "unknown"));
                        log:printInfo("Decrypted data preview: " + extractedData.toString().substring(0, 200) + "...");
                    } else {
                        log:printError("Failed to decrypt lab result data", decryptedData);
                        // Fall back to trying to parse as plain JSON
                        json|error parsedData = dataString.fromJsonString();
                        if parsedData is json {
                            extractedData = parsedData;
                            log:printInfo("Used fallback JSON parsing for legacy data");
                        }
                    }
                } else {
                    log:printInfo("Data is not encrypted, parsing as plain JSON");
                    // Try to parse as plain JSON (legacy data)
                    json|error parsedData = dataString.fromJsonString();
                    if parsedData is json {
                        extractedData = parsedData;
                        log:printInfo("Successfully parsed as plain JSON");
                    }
                }
            } else {
                log:printError("Failed to get encryption service", encryptionServiceResult);
                // Fall back to parsing as plain JSON
                json|error parsedData = dataString.fromJsonString();
                if parsedData is json {
                    extractedData = parsedData;
                }
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
            testTypeId: "1", // Default test type ID
            status: dbRecord.status,
            results: extractedData,
            createdAt: createdAtStr,
            updatedAt: createdAtStr
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
            "totalReports": 0,
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global lab result service instance
public final LabResultService labResultService = new;

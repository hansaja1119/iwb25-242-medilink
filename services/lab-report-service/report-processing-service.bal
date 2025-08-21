import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/postgresql;

# Report Processing Service for extracting data from lab reports
public class ReportProcessingService {

    # Process a lab report file and extract data
    # + sampleId - Sample ID
    # + request - Report processing request
    # + return - Processing response or error
    public function processReport(string sampleId, ReportProcessRequest request) returns ReportProcessResponse|error {
        log:printInfo("Starting report processing for sample: " + sampleId);

        // 1. Validate input
        log:printInfo("Processing report file: " + request.reportFilePath);

        // 2. Get sample details to determine test type
        LabSampleRecord sampleRecord = check self.getSampleDetails(sampleId);

        // 3. Get test type configuration
        json testTypeConfig = check self.getTestTypeConfig(sampleRecord.testTypeId.toString());

        // 4. Extract data using Python scripts (mock for now)
        json extractedData = check self.extractDataFromReport(request.reportFilePath, sampleRecord.testTypeId.toString(), testTypeConfig);

        // 5. Encrypt the extracted data (simplified for now)
        string encryptedData = check self.encryptData(extractedData);

        // 6. Store result in database
        string resultId = check self.storeLabResult(sampleId, sampleRecord.testTypeId.toString(), encryptedData, request.reportFilePath);

        string timestamp = time:utcToString(time:utcNow());

        log:printInfo("Report processing completed for sample: " + sampleId + ", result ID: " + resultId);

        return {
            resultId: resultId,
            sampleId: sampleId,
            testTypeId: sampleRecord.testTypeId.toString(),
            extractedData: extractedData,
            status: "processed",
            processedAt: timestamp,
            processedBy: request?.processedBy
        };
    }

    # Get sample details from database
    # + sampleId - Sample ID
    # + return - Sample record or error
    private function getSampleDetails(string sampleId) returns LabSampleRecord|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error sampleIdInt = int:fromString(sampleId);
        if sampleIdInt is error {
            return error("Invalid sample ID format");
        }

        log:printInfo("Looking up sample with ID: " + sampleId);

        LabSampleRecord|sql:Error result = dbClient->queryRow(`
            SELECT * FROM lab_sample WHERE id = ${sampleIdInt}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                log:printError("Sample not found with ID: " + sampleId);
                return error("Sample not found with ID: " + sampleId);
            }
            log:printError("Database error while looking up sample", result);
            return error("Failed to get sample details: " + result.message());
        }

        log:printInfo("Found sample with test_type_id: " + result.testTypeId.toString());
        return result;
    }

    # Get test type configuration from database
    # + testTypeId - Test type ID
    # + return - Test type configuration JSON
    private function getTestTypeConfig(string testTypeId) returns json|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error typeIdInt = int:fromString(testTypeId);
        if typeIdInt is error {
            return error("Invalid test type ID format");
        }

        log:printInfo("Looking up test type with ID: " + testTypeId);

        TestTypeRecord|sql:Error result = dbClient->queryRow(`
            SELECT * FROM test_types WHERE id = ${typeIdInt}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                log:printError("Test type not found with ID: " + testTypeId);
                return error("Test type not found with ID: " + testTypeId);
            }
            log:printError("Database error while looking up test type", result);
            return error("Failed to get test type: " + result.message());
        }

        log:printInfo("Found test type: " + result.label);

        // Create configuration JSON for Python parser
        json config = {
            "testTypeId": result.id,
            "label": result.label,
            "category": result.category,
            "value": result.value,
            "parser_module": result.parser_module ?: "parser_lab_report",
            "parser_class": result.parser_class ?: "LabReportParser"
        };

        return config;
    }

    # Extract data from report using Python scripts (mock implementation)
    # + filePath - Report file path
    # + testTypeId - Test type ID
    # + testTypeConfig - Test type configuration
    # + return - Extracted data JSON
    private function extractDataFromReport(string filePath, string testTypeId, json testTypeConfig) returns json|error {
        log:printInfo("Mock Python extraction for file: " + filePath + ", test type: " + testTypeId);

        // Mock extracted data based on test type
        json extractedData = {
            "patient_name": "John Doe",
            "patient_id": "P12345",
            "date": "2024-12-21",
            "test_results": self.getMockTestResults(testTypeId),
            "extraction_timestamp": time:utcToString(time:utcNow()),
            "file_processed": filePath
        };

        log:printInfo("Mock extraction completed for test type: " + testTypeId);
        return extractedData;
    }

    # Get mock test results based on test type
    # + testTypeId - Test type ID
    # + return - Mock test results
    private function getMockTestResults(string testTypeId) returns json {
        // Return different mock data based on test type
        if testTypeId == "1" {
            // FBC results
            return {
                "hemoglobin": "14.5 g/dL",
                "white_blood_cells": "7500 /μL",
                "platelets": "250000 /μL",
                "hematocrit": "42.5%"
            };
        } else if testTypeId == "2" {
            // Lipid profile
            return {
                "total_cholesterol": "180 mg/dL",
                "triglycerides": "120 mg/dL",
                "hdl_cholesterol": "55 mg/dL",
                "ldl_cholesterol": "110 mg/dL"
            };
        } else {
            // Generic results
            return {
                "test_parameter_1": "Normal",
                "test_parameter_2": "Within range",
                "test_parameter_3": "No abnormalities detected"
            };
        }
    }

    # Encrypt extracted data (simplified implementation)
    # + data - Data to encrypt
    # + return - Encrypted data string
    private function encryptData(json data) returns string|error {
        // For now, return as JSON string (encryption can be added later)
        // In production, this would use proper encryption with the Node.js encryption utils
        log:printInfo("Encrypting extracted data (mock implementation)");
        return data.toJsonString();
    }

    # Store lab result in database
    # + sampleId - Sample ID
    # + testTypeId - Test type ID
    # + encryptedData - Encrypted extracted data
    # + reportFilePath - Path to the report file
    # + return - Generated result ID
    private function storeLabResult(string sampleId, string testTypeId, string encryptedData, string reportFilePath) returns string|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert IDs to integers
        int|error sampleIdInt = int:fromString(sampleId);
        if sampleIdInt is error {
            return error("Invalid sample ID format");
        }

        // Insert into lab_result table
        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO lab_result ("labSampleId", status, "extractedData", "reportUrl")
            VALUES (${sampleIdInt}, 'processed', ${encryptedData}, ${reportFilePath})
            RETURNING id
        `);

        if result is sql:Error {
            log:printError("Failed to store lab result", result);
            return error("Failed to store lab result: " + result.message());
        }

        // Get the generated ID
        int|string? lastId = result.lastInsertId;
        if lastId is string {
            return lastId;
        } else if lastId is int {
            return lastId.toString();
        } else {
            return error("Failed to get generated lab result ID");
        }
    }

    # Get processing statistics
    # + return - Processing statistics
    public function getProcessingStats() returns json|error {
        postgresql:Client dbClient = check getDbClient();

        // Get total processed results
        record {int count;}|sql:Error totalResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result WHERE status = 'processed'`);
        int totalProcessed = totalResult is record {int count;} ? totalResult.count : 0;

        // Get results processed today
        record {int count;}|sql:Error todayResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_result WHERE status = 'processed' AND DATE(createdAt) = CURRENT_DATE`);
        int processedToday = todayResult is record {int count;} ? todayResult.count : 0;

        return {
            "totalProcessed": totalProcessed,
            "processedToday": processedToday,
            "lastUpdated": time:utcToString(time:utcNow())
        };
    }
}

# Global report processing service instance
public final ReportProcessingService reportProcessingService = new;

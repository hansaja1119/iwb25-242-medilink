import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/postgresql;

# Lab Sample Service for managing lab samples

# Lab Sample Service for managing lab samples
public class LabSampleService {

    # Create a new lab sample
    # + sampleData - Sample data without ID
    # + return - Created sample or error
    public function createSample(LabSampleCreate sampleData) returns LabSample|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert expectedTime string to time:Civil if provided
        time:Civil? expectedTimeCivil = ();
        string? expectedTimeStr = sampleData.expectedTime;
        if expectedTimeStr is string {
            time:Utc|error utcTime = time:utcFromString(expectedTimeStr);
            if utcTime is time:Utc {
                expectedTimeCivil = time:utcToCivil(utcTime);
            } else {
                return error("Invalid expectedTime format. Use ISO 8601 format (e.g., 2025-08-10T14:00:00.000Z)");
            }
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            INSERT INTO lab_sample ("labId", barcode, "testTypeId", "sampleType", volume, container, "patientId", status, priority, notes, "expectedTime")
            VALUES (${sampleData.labId}, ${sampleData.barcode}, ${sampleData.testTypeId}, ${sampleData.sampleType}, 
                    ${sampleData?.volume}, ${sampleData?.container}, ${sampleData.patientId}, ${sampleData.status}, 
                    ${sampleData?.priority}, ${sampleData?.notes}, ${expectedTimeCivil})
            RETURNING id
        `);

        if result is sql:Error {
            log:printError("Failed to create lab sample", result);
            return error("Failed to create lab sample: " + result.message());
        }

        // Get the generated ID from the result
        string generatedId;
        int|string? lastId = result.lastInsertId;
        if lastId is string {
            generatedId = lastId;
        } else if lastId is int {
            generatedId = lastId.toString();
        } else {
            return error("Failed to get generated lab sample ID");
        }

        log:printInfo("Lab sample created with ID: " + generatedId);
        return self.getSampleById(generatedId);
    }

    # Get sample by ID
    # + sampleId - Sample ID
    # + return - Sample or error
    public function getSample(string sampleId) returns LabSample|error {
        return self.getSampleById(sampleId);
    }

    # Get sample by ID (internal method)
    # + id - Sample ID
    # + return - Sample or error
    public function getSampleById(string id) returns LabSample|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(id);
        if idInt is error {
            return error("Invalid sample ID format");
        }

        LabSampleRecord|sql:Error result = dbClient->queryRow(`
            SELECT * FROM lab_sample WHERE id = ${idInt}
        `);

        if result is sql:Error {
            if result is sql:NoRowsError {
                return error("Lab sample not found");
            }
            return error("Failed to get lab sample: " + result.message());
        }

        LabSample labSample = {
            id: result.id is int ? result.id.toString() : "",
            labId: result.labId,
            barcode: result.barcode,
            testTypeId: result.testTypeId,
            sampleType: result.sampleType,
            volume: result.volume,
            container: result.container,
            patientId: result.patientId,
            createdAt: result.createdAt,
            expectedTime: result.expectedTime,
            updatedAt: result.updatedAt,
            status: result.status,
            priority: result.priority,
            notes: result.notes
        };
        return labSample;
    }

    # Get all samples for a patient
    # + patientId - Patient ID
    # + return - Array of samples
    public function getSamplesByPatient(string patientId) returns LabSample[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<LabSampleRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_sample WHERE "patientId" = ${patientId} ORDER BY "createdAt" DESC
        `);

        LabSample[] samples = [];
        check from LabSampleRecord sampleRecord in resultStream
            do {
                samples.push({
                    id: sampleRecord.id is int ? sampleRecord.id.toString() : "",
                    labId: sampleRecord.labId,
                    barcode: sampleRecord.barcode,
                    testTypeId: sampleRecord.testTypeId,
                    sampleType: sampleRecord.sampleType,
                    volume: sampleRecord.volume,
                    container: sampleRecord.container,
                    patientId: sampleRecord.patientId,
                    createdAt: sampleRecord.createdAt,
                    expectedTime: sampleRecord.expectedTime,
                    updatedAt: sampleRecord.updatedAt,
                    status: sampleRecord.status,
                    priority: sampleRecord.priority,
                    notes: sampleRecord.notes
                });
            };

        check resultStream.close();
        return samples;
    }

    # Get samples by status
    # + status - Sample status
    # + return - Array of samples
    public function getSamplesByStatus(string status) returns LabSample[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<LabSampleRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_sample WHERE status = ${status} ORDER BY "createdAt" DESC
        `);

        LabSample[] samples = [];
        check from LabSampleRecord sampleRecord in resultStream
            do {
                samples.push({
                    id: sampleRecord.id is int ? sampleRecord.id.toString() : "",
                    labId: sampleRecord.labId,
                    barcode: sampleRecord.barcode,
                    testTypeId: sampleRecord.testTypeId,
                    sampleType: sampleRecord.sampleType,
                    volume: sampleRecord.volume,
                    container: sampleRecord.container,
                    patientId: sampleRecord.patientId,
                    createdAt: sampleRecord.createdAt,
                    expectedTime: sampleRecord.expectedTime,
                    updatedAt: sampleRecord.updatedAt,
                    status: sampleRecord.status,
                    priority: sampleRecord.priority,
                    notes: sampleRecord.notes
                });
            };

        check resultStream.close();
        return samples;
    }

    # Update sample status
    # + sampleId - Sample ID
    # + status - New status
    # + notes - Optional notes
    # + return - Updated sample or error
    public function updateSampleStatus(string sampleId, string status, string? notes = ()) returns LabSample|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(sampleId);
        if idInt is error {
            return error("Invalid sample ID format");
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE lab_sample 
            SET status = ${status}, 
                notes = COALESCE(${notes}, notes),
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to update sample status: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Lab sample not found");
        }

        log:printInfo("Sample status updated: " + sampleId + " -> " + status);
        return check self.getSampleById(sampleId);
    }

    # Process sample (move to processing status)
    # + sampleId - Sample ID
    # + processedBy - Who is processing
    # + return - Updated sample or error
    public function processSample(string sampleId, string processedBy) returns LabSample|error {
        // First check if sample exists and has correct status
        LabSample currentSample = check self.getSampleById(sampleId);

        if currentSample.status != "collected" && currentSample.status != "pending" {
            return error("Sample must be in 'collected' or 'pending' status to process");
        }

        string newNotes = "Processed by: " + processedBy;
        if currentSample.notes is string {
            newNotes = <string>currentSample.notes + "; " + newNotes;
        }

        return self.updateSampleStatus(sampleId, "processing", newNotes);
    }

    # Complete sample processing
    # + sampleId - Sample ID
    # + resultData - Lab result data
    # + return - Lab result or error
    public function completeSample(string sampleId, LabResultCreate resultData) returns FullLabResult|error {
        // First check if sample exists and has correct status
        LabSample currentSample = check self.getSampleById(sampleId);

        if currentSample.status != "processing" {
            return error("Sample must be in 'processing' status to complete");
        }

        // Update sample status to completed
        _ = check self.updateSampleStatus(sampleId, "completed", "Completed with lab results");

        // For now, return a mock result (this should integrate with lab result service)
        string timestamp = time:utcToString(time:utcNow());
        FullLabResult result = {
            id: sampleId + "_result",
            sampleId: sampleId,
            testTypeId: resultData.testTypeId,
            results: resultData.results,
            normalRanges: resultData?.normalRanges,
            status: "completed",
            reviewedBy: resultData?.reviewedBy,
            reviewedAt: (),
            completedAt: (),
            notes: resultData?.notes,
            resultDate: resultData?.resultDate,
            resultValue: resultData?.resultValue,
            createdAt: timestamp,
            updatedAt: timestamp
        };

        log:printInfo("Sample completed: " + sampleId);
        return result;
    }

    # Get all samples
    # + return - Array of all samples
    public function getAllSamples() returns LabSample[]|error {
        postgresql:Client dbClient = check getDbClient();

        stream<LabSampleRecord, sql:Error?> resultStream = dbClient->query(`
            SELECT * FROM lab_sample ORDER BY "createdAt" DESC
        `);

        LabSample[] samples = [];
        check from LabSampleRecord sampleRecord in resultStream
            do {
                samples.push({
                    id: sampleRecord.id is int ? sampleRecord.id.toString() : "",
                    labId: sampleRecord.labId,
                    barcode: sampleRecord.barcode,
                    testTypeId: sampleRecord.testTypeId,
                    sampleType: sampleRecord.sampleType,
                    volume: sampleRecord.volume,
                    container: sampleRecord.container,
                    patientId: sampleRecord.patientId,
                    createdAt: sampleRecord.createdAt,
                    expectedTime: sampleRecord.expectedTime,
                    updatedAt: sampleRecord.updatedAt,
                    status: sampleRecord.status,
                    priority: sampleRecord.priority,
                    notes: sampleRecord.notes
                });
            };

        check resultStream.close();
        return samples;
    }

    # Get sample with results
    # + sampleId - Sample ID
    # + return - Sample with results or error
    public function getSampleWithResults(string sampleId) returns json|error {
        LabSample sample = check self.getSampleById(sampleId);

        // For now, return sample without results (results integration can be added later)
        json result = {
            "sample": sample.toJson(),
            "results": []
        };
        return result;
    }

    # Delete sample (soft delete by updating status)
    # + sampleId - Sample ID
    # + return - Error if deletion fails
    public function deleteSample(string sampleId) returns error? {
        // First check if sample exists and can be deleted
        LabSample currentSample = check self.getSampleById(sampleId);

        if currentSample.status == "processing" {
            return error("Cannot delete sample that is currently being processed");
        }

        _ = check self.updateSampleStatus(sampleId, "deleted", "Sample deleted");
        log:printInfo("Sample deleted: " + sampleId);
        return;
    }

    # Get sample statistics
    # + return - Sample statistics
    public function getSampleStats() returns json|error {
        postgresql:Client dbClient = check getDbClient();

        // Get total count
        record {int count;}|sql:Error totalResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_sample WHERE status != 'deleted'`);
        int totalSamples = totalResult is record {int count;} ? totalResult.count : 0;

        // Get count by status
        record {int count;}|sql:Error collectedResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_sample WHERE status = 'collected'`);
        int collectedSamples = collectedResult is record {int count;} ? collectedResult.count : 0;

        record {int count;}|sql:Error processingResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_sample WHERE status = 'processing'`);
        int processingSamples = processingResult is record {int count;} ? processingResult.count : 0;

        record {int count;}|sql:Error completedResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_sample WHERE status = 'completed'`);
        int completedSamples = completedResult is record {int count;} ? completedResult.count : 0;

        record {int count;}|sql:Error deletedResult = dbClient->queryRow(`SELECT COUNT(*) as count FROM lab_sample WHERE status = 'deleted'`);
        int deletedSamples = deletedResult is record {int count;} ? deletedResult.count : 0;

        return {
            "totalSamples": totalSamples,
            "collectedSamples": collectedSamples,
            "processingSamples": processingSamples,
            "completedSamples": completedSamples,
            "deletedSamples": deletedSamples,
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    # Update lab sample
    # + id - Sample ID
    # + updateData - Updated sample data
    # + return - Updated sample or error
    public function updateSample(string id, LabSampleUpdate updateData) returns LabSample|error {
        postgresql:Client dbClient = check getDbClient();

        // Convert string ID to integer
        int|error idInt = int:fromString(id);
        if idInt is error {
            return error("Invalid sample ID format");
        }

        // Convert expectedTime string to time:Civil if provided
        time:Civil? expectedTimeCivil = ();
        string? expectedTimeStr = updateData.expectedTime;
        if expectedTimeStr is string {
            time:Utc|error utcTime = time:utcFromString(expectedTimeStr);
            if utcTime is time:Utc {
                expectedTimeCivil = time:utcToCivil(utcTime);
            } else {
                return error("Invalid expectedTime format. Use ISO 8601 format (e.g., 2025-08-10T14:00:00.000Z)");
            }
        }

        sql:ExecutionResult|sql:Error result = dbClient->execute(`
            UPDATE lab_sample 
            SET "labId" = COALESCE(${updateData?.labId}, "labId"), 
                barcode = COALESCE(${updateData?.barcode}, barcode),
                "testTypeId" = COALESCE(${updateData?.testTypeId}, "testTypeId"), 
                "sampleType" = COALESCE(${updateData?.sampleType}, "sampleType"), 
                volume = COALESCE(${updateData?.volume}, volume), 
                container = COALESCE(${updateData?.container}, container),
                "patientId" = COALESCE(${updateData?.patientId}, "patientId"),
                status = COALESCE(${updateData?.status}, status),
                priority = COALESCE(${updateData?.priority}, priority),
                notes = COALESCE(${updateData?.notes}, notes),
                "expectedTime" = COALESCE(${expectedTimeCivil}, "expectedTime"),
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE id = ${idInt}
        `);

        if result is sql:Error {
            return error("Failed to update lab sample: " + result.message());
        }

        if result.affectedRowCount == 0 {
            return error("Lab sample not found");
        }

        log:printInfo("Lab sample updated: " + id);
        return check self.getSampleById(id);
    }
}

# Global lab sample service instance
public final LabSampleService labSampleService = new;

import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# Lab Sample Service for managing lab samples

# Lab Sample Service for managing lab samples
public class LabSampleService {

    # In-memory storage for demo purposes (replace with database later)
    private map<LabSample> samples = {};
    private map<FullLabResult> results = {};

    # Create a new lab sample
    # + sampleData - Sample data without ID
    # + return - Created sample or error
    public function createSample(LabSampleCreate sampleData) returns LabSample|error {
        string sampleId = uuid:createType1AsString();
        time:Civil timestamp = time:utcToCivil(time:utcNow());

        LabSample sample = {
            id: sampleId,
            labId: sampleData.labId,
            barcode: sampleData.barcode,
            testTypeId: sampleData.testTypeId.toString(),
            sampleType: "blood", // Default sample type, can be customized
            volume: (),
            container: (),
            patientId: sampleData.patientId ?: "",
            collectionDate: (),
            receivedDate: (),
            status: sampleData.status,
            notes: (),
            createdAt: timestamp,
            updatedAt: timestamp
        };

        self.samples[sampleId] = sample;

        log:printInfo("Sample created: " + sampleId + " for patient: " + sample.patientId);

        // Start workflow for this sample
        FullWorkflowStatus|error workflowResult = labWorkflowService.startWorkflow(sample);
        if workflowResult is error {
            log:printError("Failed to start workflow for sample " + sampleId + ": " + workflowResult.message());
        }

        return sample;
    }

    # Get sample by ID
    # + sampleId - Sample ID
    # + return - Sample or error
    public function getSample(string sampleId) returns LabSample|error {
        LabSample? sample = self.samples[sampleId];
        if sample is LabSample {
            return sample;
        }
        return error("Sample not found");
    }

    # Get all samples for a patient
    # + patientId - Patient ID
    # + return - Array of samples
    public function getSamplesByPatient(string patientId) returns LabSample[] {
        LabSample[] patientSamples = [];
        foreach LabSample sample in self.samples {
            if sample.patientId == patientId {
                patientSamples.push(sample);
            }
        }
        return patientSamples;
    }

    # Get samples by status
    # + status - Sample status
    # + return - Array of samples
    public function getSamplesByStatus(string status) returns LabSample[] {
        LabSample[] statusSamples = [];
        foreach LabSample sample in self.samples {
            if sample.status == status {
                statusSamples.push(sample);
            }
        }
        return statusSamples;
    }

    # Update sample status
    # + sampleId - Sample ID
    # + status - New status
    # + notes - Optional notes
    # + return - Updated sample or error
    public function updateSampleStatus(string sampleId, string status, string? notes = ()) returns LabSample|error {
        LabSample? sample = self.samples[sampleId];
        if sample is () {
            return error("Sample not found");
        }

        sample.status = status;
        sample.updatedAt = time:utcToCivil(time:utcNow());

        if notes is string {
            sample.notes = notes;
        }

        self.samples[sampleId] = sample;

        log:printInfo("Sample status updated: " + sampleId + " -> " + status);

        return sample;
    }

    # Process sample (move to processing status)
    # + sampleId - Sample ID
    # + processedBy - Who is processing
    # + return - Updated sample or error
    public function processSample(string sampleId, string processedBy) returns LabSample|error {
        LabSample? sample = self.samples[sampleId];
        if sample is () {
            return error("Sample not found");
        }

        if sample.status != "collected" {
            return error("Sample must be in 'collected' status to process");
        }

        sample.status = "processing";
        sample.notes = "Processed by: " + processedBy;
        sample.updatedAt = time:utcToCivil(time:utcNow());

        self.samples[sampleId] = sample;

        log:printInfo("Sample processing started: " + sampleId + " by " + processedBy);

        return sample;
    }

    # Complete sample processing
    # + sampleId - Sample ID
    # + resultData - Lab result data
    # + return - Lab result or error
    public function completeSample(string sampleId, LabResultCreate resultData) returns FullLabResult|error {
        LabSample? sample = self.samples[sampleId];
        if sample is () {
            return error("Sample not found");
        }

        if sample.status != "processing" {
            return error("Sample must be in 'processing' status to complete");
        }

        string resultId = uuid:createType1AsString();
        string timestamp = time:utcToString(time:utcNow());

        FullLabResult result = {
            id: resultId,
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

        self.results[resultId] = result;

        // Update sample status
        sample.status = "completed";
        sample.notes = "Completed with result: " + resultId;
        sample.updatedAt = time:utcToCivil(time:utcNow());
        self.samples[sampleId] = sample;

        log:printInfo("Sample completed: " + sampleId + " with result: " + resultId);

        return result;
    }

    # Get all samples
    # + return - Array of all samples
    public function getAllSamples() returns LabSample[] {
        LabSample[] allSamples = [];
        foreach LabSample sample in self.samples {
            allSamples.push(sample);
        }
        return allSamples;
    }

    # Get sample with results
    # + sampleId - Sample ID
    # + return - Sample with results or error
    public function getSampleWithResults(string sampleId) returns json|error {
        LabSample sample = check self.getSample(sampleId);

        FullLabResult[] sampleResults = [];
        foreach FullLabResult result in self.results {
            if result.sampleId == sampleId {
                sampleResults.push(result);
            }
        }

        json result = {
            "sample": sample.toJson(),
            "results": sampleResults.toJson()
        };
        return result;
    }

    # Delete sample (soft delete by updating status)
    # + sampleId - Sample ID
    # + return - Error if deletion fails
    public function deleteSample(string sampleId) returns error? {
        LabSample? sample = self.samples[sampleId];
        if sample is () {
            return error("Sample not found");
        }

        if sample.status == "processing" {
            return error("Cannot delete sample that is currently being processed");
        }

        sample.status = "deleted";
        sample.updatedAt = time:utcToCivil(time:utcNow());
        self.samples[sampleId] = sample;

        log:printInfo("Sample deleted: " + sampleId);
        return;
    }

    # Get sample statistics
    # + return - Sample statistics
    public function getSampleStats() returns json {
        int totalSamples = 0;
        int collectedSamples = 0;
        int processingSamples = 0;
        int completedSamples = 0;
        int deletedSamples = 0;

        foreach LabSample sample in self.samples {
            totalSamples += 1;
            match sample.status {
                "collected" => {
                    collectedSamples += 1;
                }
                "processing" => {
                    processingSamples += 1;
                }
                "completed" => {
                    completedSamples += 1;
                }
                "deleted" => {
                    deletedSamples += 1;
                }
            }
        }

        return {
            "totalSamples": totalSamples,
            "collectedSamples": collectedSamples,
            "processingSamples": processingSamples,
            "completedSamples": completedSamples,
            "deletedSamples": deletedSamples,
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global lab sample service instance
public final LabSampleService labSampleService = new;

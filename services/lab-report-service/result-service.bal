import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# Lab Result Service for managing lab results and reports
public class LabResultService {

    # In-memory storage for demo purposes (replace with database later)
    private map<FullLabResult> results = {};
    private map<LabReport> reports = {};

    # Create a new lab result
    # + resultData - Result data without ID
    # + return - Created result or error
    public function createResult(LabResultCreate resultData) returns FullLabResult|error {
        string resultId = uuid:createType1AsString();
        string timestamp = time:utcToString(time:utcNow());

        FullLabResult result = {
            id: resultId,
            sampleId: <string>resultData["sampleId"],
            testTypeId: <string>resultData["testTypeId"],
            results: <json>resultData["results"],
            normalRanges: <json?>resultData["normalRanges"],
            status: "pending_review",
            reviewedBy: <string?>resultData["reviewedBy"],
            reviewedAt: (),
            completedAt: (),
            notes: <string?>resultData["notes"],
            resultDate: <string>resultData["resultDate"],
            resultValue: <string>resultData["resultValue"],
            createdAt: timestamp,
            updatedAt: timestamp
        };

        self.results[resultId] = result;

        log:printInfo("Lab result created: " + resultId + " for sample: " + <string>resultData["sampleId"]);

        return result;
    }

    # Get result by ID
    # + resultId - Result ID
    # + return - Result or error
    public function getResult(string resultId) returns FullLabResult|error {
        FullLabResult? result = self.results[resultId];
        if result is FullLabResult {
            return result;
        }
        return error("Result not found");
    }

    # Get results by sample ID
    # + sampleId - Sample ID
    # + return - Array of results
    public function getResultsBySample(string sampleId) returns FullLabResult[] {
        FullLabResult[] sampleResults = [];
        foreach FullLabResult result in self.results {
            if result.sampleId == sampleId {
                sampleResults.push(result);
            }
        }
        return sampleResults;
    }

    # Update result
    # + resultId - Result ID
    # + updateData - Update data
    # + return - Updated result or error
    public function updateResult(string resultId, LabResultUpdate updateData) returns FullLabResult|error {
        FullLabResult? result = self.results[resultId];
        if result is () {
            return error("Result not found");
        }

        // Update fields if provided
        if updateData?.results is json {
            result.results = updateData?.results;
        }

        if updateData?.normalRanges is json {
            result["normalRanges"] = updateData?.normalRanges;
        }

        if updateData?.status is string {
            result.status = <string>updateData?.status;
        }

        if updateData?.reviewedBy is string {
            result["reviewedBy"] = updateData?.reviewedBy;
        }

        if updateData?.notes is string {
            result["notes"] = updateData?.notes;
        }

        result.updatedAt = time:utcToString(time:utcNow());

        self.results[resultId] = result;

        log:printInfo("Lab result updated: " + resultId);

        return result;
    }

    # Review and approve result
    # + resultId - Result ID
    # + reviewedBy - Reviewer name
    # + notes - Review notes
    # + return - Updated result or error
    public function reviewResult(string resultId, string reviewedBy, string? notes = ()) returns FullLabResult|error {
        FullLabResult? result = self.results[resultId];
        if result is () {
            return error("Result not found");
        }

        result.status = "reviewed";
        result["reviewedBy"] = reviewedBy;
        result["reviewedAt"] = time:utcToString(time:utcNow());

        if notes is string {
            result["notes"] = notes;
        }

        result.updatedAt = time:utcToString(time:utcNow());

        self.results[resultId] = result;

        log:printInfo("Lab result reviewed: " + resultId + " by " + reviewedBy);

        return result;
    }

    # Generate lab report from results
    # + sampleId - Sample ID
    # + templateId - Template ID
    # + generatedBy - Who generated the report
    # + return - Generated report or error
    public function generateReport(string sampleId, string? templateId = (), string? generatedBy = ()) returns LabReport|error {
        // Get all results for the sample
        FullLabResult[] sampleResults = self.getResultsBySample(sampleId);

        if sampleResults.length() == 0 {
            return error("No results found for sample");
        }

        // Check if all results are reviewed
        foreach FullLabResult result in sampleResults {
            if result.status != "reviewed" {
                return error("All results must be reviewed before generating report");
            }
        }

        string reportId = uuid:createType1AsString();
        string timestamp = time:utcToString(time:utcNow());

        // Generate report summary
        json reportSummary = self.generateReportSummary(sampleResults);

        LabReport report = {
            id: reportId,
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

        self.reports[reportId] = report;

        log:printInfo("Lab report generated: " + reportId + " for sample: " + sampleId);

        return report;
    }

    # Get report by ID
    # + reportId - Report ID
    # + return - Report or error
    public function getReport(string reportId) returns LabReport|error {
        LabReport? report = self.reports[reportId];
        if report is LabReport {
            return report;
        }
        return error("Report not found");
    }

    # Get reports by sample ID
    # + sampleId - Sample ID
    # + return - Array of reports
    public function getReportsBySample(string sampleId) returns LabReport[] {
        LabReport[] sampleReports = [];
        foreach LabReport report in self.reports {
            if report.sampleId == sampleId {
                sampleReports.push(report);
            }
        }
        return sampleReports;
    }

    # Finalize report (make it official)
    # + reportId - Report ID
    # + finalizedBy - Who finalized the report
    # + return - Updated report or error
    public function finalizeReport(string reportId, string finalizedBy) returns LabReport|error {
        LabReport? report = self.reports[reportId];
        if report is () {
            return error("Report not found");
        }

        if report.status == "finalized" {
            return error("Report is already finalized");
        }

        report.status = "finalized";
        report.finalizedBy = finalizedBy;
        report.finalizedAt = time:utcToString(time:utcNow());
        report.updatedAt = time:utcToString(time:utcNow());

        self.reports[reportId] = report;

        log:printInfo("Lab report finalized: " + reportId + " by " + finalizedBy);

        return report;
    }

    # Get all results
    # + return - Array of all results
    public function getAllResults() returns FullLabResult[] {
        FullLabResult[] allResults = [];
        foreach FullLabResult result in self.results {
            allResults.push(result);
        }
        return allResults;
    }

    # Get all reports
    # + return - Array of all reports
    public function getAllReports() returns LabReport[] {
        LabReport[] allReports = [];
        foreach LabReport report in self.reports {
            allReports.push(report);
        }
        return allReports;
    }

    # Get results by status
    # + status - Result status
    # + return - Array of results
    public function getResultsByStatus(string status) returns FullLabResult[] {
        FullLabResult[] statusResults = [];
        foreach FullLabResult result in self.results {
            if result.status == status {
                statusResults.push(result);
            }
        }
        return statusResults;
    }

    # Generate report summary from results
    # + results - Array of lab results
    # + return - Report summary JSON
    private function generateReportSummary(FullLabResult[] results) returns json {
        json[] resultSummaries = [];

        foreach FullLabResult result in results {
            json resultSummary = {
                "resultId": result.id,
                "testTypeId": <string>result["testTypeId"],
                "results": <json>result["results"],
                "normalRanges": <json>result["normalRanges"],
                "status": result.status,
                "reviewedBy": <string?>result["reviewedBy"],
                "reviewedAt": <string?>result["reviewedAt"],
                "notes": <string?>result["notes"]
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
    public function getResultStats() returns json {
        int totalResults = 0;
        int pendingReview = 0;
        int reviewed = 0;
        int flagged = 0;

        foreach FullLabResult result in self.results {
            totalResults += 1;
            match result.status {
                "pending_review" => {
                    pendingReview += 1;
                }
                "reviewed" => {
                    reviewed += 1;
                }
                "flagged" => {
                    flagged += 1;
                }
            }
        }

        return {
            "totalResults": totalResults,
            "pendingReview": pendingReview,
            "reviewed": reviewed,
            "flagged": flagged,
            "totalReports": self.reports.length(),
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global lab result service instance
public final LabResultService labResultService = new;

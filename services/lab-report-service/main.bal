import ballerina/http;
import ballerina/log;
import ballerina/time;

// Configuration
configurable int servicePort = 3004;

# Log startup information
function init() {
    log:printInfo("=================================================");
    log:printInfo("        MediLink Lab Report Service Starting     ");
    log:printInfo("=================================================");
    log:printInfo(string `Port: ${servicePort}`);

    // Initialize database connection
    error? dbInitResult = initDatabase();
    if dbInitResult is error {
        log:printError("Failed to initialize database", dbInitResult);
        panic error("Database initialization failed: " + dbInitResult.message());
    }
    log:printInfo("Database initialized successfully");

    log:printInfo("Available endpoints:");
    log:printInfo(string `  - Health: http://localhost:${servicePort}/health`);
    log:printInfo(string `  - Test Types: http://localhost:${servicePort}/testtypes`);
    log:printInfo(string `  - Lab Samples: http://localhost:${servicePort}/samples`);
    log:printInfo(string `  - Lab Results: http://localhost:${servicePort}/results`);
    log:printInfo(string `  - Lab Reports: http://localhost:${servicePort}/reports`);
    log:printInfo(string `  - Templates: http://localhost:${servicePort}/templates`);
    log:printInfo(string `  - Workflows: http://localhost:${servicePort}/workflows`);
    log:printInfo("=================================================");
    log:printInfo("Lab Report Service is ready to accept requests!");
    log:printInfo("=================================================");
}

// Service definition
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    }
}
service / on new http:Listener(servicePort) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "healthy",
            "service": "lab-report-service",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.0.0"
        };
    }

    // Test Types endpoints
    resource function get testtypes() returns TestType[]|error {
        return testTypeService.getAllTestTypes();
    }

    resource function post testtypes(@http:Payload TestType testTypeData) returns TestType|error {
        return testTypeService.createTestType(testTypeData);
    }

    // resource function get testtypes/[string id]() returns TestType|error {
    //     return testTypeService.getTestType(id);
    // }

    resource function put testtypes/[string id](@http:Payload TestType updateData) returns TestType|error {
        return testTypeService.updateTestType(id, updateData);
    }

    resource function delete testtypes/[string id]() returns json|error {
        check testTypeService.deleteTestType(id);
        return {"message": "Test type deleted successfully"};
    }

    // Lab Samples endpoints
    resource function get samples() returns LabSample[]|error {
        return labSampleService.getAllSamples();
    }

    resource function post samples(@http:Payload LabSampleCreate sampleData) returns LabSample|error {
        return labSampleService.createSample(sampleData);
    }

    resource function get samples/[string id]() returns LabSample|error {
        return labSampleService.getSample(id);
    }

    resource function get samples/patient/[string patientId]() returns LabSample[]|error {
        return labSampleService.getSamplesByPatient(patientId);
    }

    resource function get samples/status/[string status]() returns LabSample[]|error {
        return labSampleService.getSamplesByStatus(status);
    }

    resource function put samples/[string id]/status(@http:Payload json statusData) returns LabSample|error {
        json statusValue = check statusData.status;
        string status = statusValue is string ? statusValue : "";
        json notesValue = check statusData.notes;
        string? notes = notesValue is string ? notesValue : ();
        return labSampleService.updateSampleStatus(id, status, notes);
    }

    resource function put samples/[string id]/process(@http:Payload json processData) returns LabSample|error {
        json processedByValue = check processData.processedBy;
        string processedBy = processedByValue is string ? processedByValue : "";
        return labSampleService.processSample(id, processedBy);
    }

    resource function put samples/[string id]/complete(@http:Payload LabResultCreate resultData) returns FullLabResult|error {
        return labSampleService.completeSample(id, resultData);
    }

    resource function get samples/[string id]/results() returns json|error {
        return labSampleService.getSampleWithResults(id);
    }

    resource function delete samples/[string id]() returns json|error {
        check labSampleService.deleteSample(id);
        return {"message": "Sample deleted successfully"};
    }

    resource function get samples/stats() returns json|error {
        return labSampleService.getSampleStats();
    }

    // Lab Results endpoints
    resource function get results() returns FullLabResult[]|error {
        return labResultService.getAllResults();
    }

    resource function post results(@http:Payload LabResultCreate resultData) returns FullLabResult|error {
        return labResultService.createResult(resultData);
    }

    resource function get results/[string id]() returns FullLabResult|error {
        return labResultService.getResult(id);
    }

    resource function get results/sample/[string sampleId]() returns FullLabResult[]|error {
        return labResultService.getResultsBySample(sampleId);
    }

    resource function get results/status/[string status]() returns FullLabResult[]|error {
        return labResultService.getResultsByStatus(status);
    }

    resource function put results/[string id](@http:Payload LabResultUpdate updateData) returns FullLabResult|error {
        return labResultService.updateResult(id, updateData);
    }

    resource function put results/[string id]/review(@http:Payload json reviewData) returns FullLabResult|error {
        json reviewedByValue = check reviewData.reviewedBy;
        string reviewedBy = reviewedByValue is string ? reviewedByValue : "";
        json notesValue = check reviewData.notes;
        string? notes = notesValue is string ? notesValue : ();
        return labResultService.reviewResult(id, reviewedBy, notes);
    }

    resource function get results/stats() returns json|error {
        return labResultService.getResultStats();
    }

    // Lab Reports endpoints
    resource function get reports() returns LabReport[]|error {
        return labResultService.getAllReports();
    }

    resource function post reports/generate(@http:Payload json reportRequest) returns LabReport|error {
        json sampleIdValue = check reportRequest.sampleId;
        string sampleId = sampleIdValue is string ? sampleIdValue : "";
        json templateIdValue = check reportRequest.templateId;
        string? templateId = templateIdValue is string ? templateIdValue : ();
        json generatedByValue = check reportRequest.generatedBy;
        string? generatedBy = generatedByValue is string ? generatedByValue : ();
        return labResultService.generateReport(sampleId, templateId, generatedBy);
    }

    resource function get reports/[string id]() returns LabReport|error {
        return labResultService.getReport(id);
    }

    resource function get reports/sample/[string sampleId]() returns LabReport[]|error {
        return labResultService.getReportsBySample(sampleId);
    }

    resource function put reports/[string id]/finalize(@http:Payload json finalizeData) returns LabReport|error {
        json finalizedByValue = check finalizeData.finalizedBy;
        string finalizedBy = finalizedByValue is string ? finalizedByValue : "";
        return labResultService.finalizeReport(id, finalizedBy);
    }

    // Templates endpoints
    resource function get templates() returns ReportTemplate[]|error {
        return templateService.getAllTemplates();
    }

    resource function get templates/active() returns ReportTemplate[]|error {
        return templateService.getActiveTemplates();
    }

    resource function post templates(@http:Payload ReportTemplateCreate templateData) returns ReportTemplate|error {
        return templateService.createTemplate(templateData);
    }

    resource function get templates/[string id]() returns ReportTemplate|error {
        return templateService.getTemplate(id);
    }

    resource function get templates/testtype/[string testTypeId]() returns ReportTemplate[]|error {
        return templateService.getTemplatesByTestType(testTypeId);
    }

    resource function put templates/[string id](@http:Payload ReportTemplateUpdate updateData) returns ReportTemplate|error {
        return templateService.updateTemplate(id, updateData);
    }

    resource function put templates/[string id]/activate() returns ReportTemplate|error {
        return templateService.activateTemplate(id);
    }

    resource function put templates/[string id]/deactivate() returns ReportTemplate|error {
        return templateService.deactivateTemplate(id);
    }

    resource function post templates/[string id]/generate(@http:Payload json generateRequest) returns json|error {
        // This would require result data in the request
        LabResult[] resultData = []; // Placeholder - in real implementation, get from request
        return templateService.generateReportFromTemplate(id, resultData);
    }

    resource function get templates/stats() returns json|error {
        return templateService.getTemplateStats();
    }

    // Workflow endpoints
    resource function get workflows/active() returns FullWorkflowStatus[]|error {
        return labWorkflowService.getActiveWorkflows();
    }

    resource function get workflows/[string id]() returns FullWorkflowStatus|error {
        return labWorkflowService.getWorkflowStatus(id);
    }

    resource function post workflows/[string id]/process() returns json|error {
        check labWorkflowService.processNextStep(id);
        return {"message": "Workflow step processed"};
    }

    resource function put workflows/[string id]/step/[int stepIndex]/complete(@http:Payload json stepData) returns json|error {
        json resultValue = check stepData.result;
        check labWorkflowService.completeStep(id, stepIndex, resultValue);
        return {"message": "Workflow step completed"};
    }

    // resource function put workflows/[string id]/step/[int stepIndex]/fail(@http:Payload json failData) returns json|error {
    //     json errorValue = check failData.errorMessage;
    //     string errorMessage = errorValue is string ? errorValue : "";
    //     check labWorkflowService.failStep(id, stepIndex, errorMessage);
    //     return {"message": "Workflow step failed"};
    // }

    resource function get workflows/stats() returns json|error {
        return labWorkflowService.getWorkflowStats();
    }

    // Legacy endpoints for compatibility with API Gateway expectations
    resource function get workflow() returns json {
        return {
            "message": "Workflow endpoint",
            "status": "operational",
            "activeWorkflows": labWorkflowService.getActiveWorkflows().length(),
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

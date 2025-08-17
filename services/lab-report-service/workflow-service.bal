import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# Lab Workflow Service for managing lab processing workflows
public class LabWorkflowService {

    # In-memory storage for demo purposes (replace with database later)
    private map<FullWorkflowStatus> workflows = {};
    private map<LabSample> samples = {};

    # Start a new lab workflow
    # + sampleData - Lab sample data
    # + return - Workflow status or error
    public function startWorkflow(LabSample sampleData) returns FullWorkflowStatus|error {
        string workflowId = uuid:createType1AsString();
        string timestamp = time:utcToString(time:utcNow());

        // Store the sample
        self.samples[sampleData.id.toBalString()] = sampleData;

        // Create initial workflow status
        FullWorkflowStatus workflow = {
            id: workflowId,
            status: "started",
            sampleId: sampleData.id.toBalString(),
            steps: [
                {
                    name: "sample_received",
                    status: "completed",
                    startTime: timestamp,
                    endTime: timestamp,
                    result: {"message": "Sample received and registered"},
                    errorMessage: ()
                },
                {
                    name: "sample_preparation",
                    status: "pending",
                    startTime: timestamp,
                    endTime: (),
                    result: (),
                    errorMessage: ()
                },
                {
                    name: "testing",
                    status: "pending",
                    startTime: timestamp,
                    endTime: (),
                    result: (),
                    errorMessage: ()
                },
                {
                    name: "result_analysis",
                    status: "pending",
                    startTime: timestamp,
                    endTime: (),
                    result: (),
                    errorMessage: ()
                },
                {
                    name: "report_generation",
                    status: "pending",
                    startTime: timestamp,
                    endTime: (),
                    result: (),
                    errorMessage: ()
                }
            ],
            startTime: timestamp,
            endTime: (),
            errorMessage: ()
        };

        self.workflows[workflowId] = workflow;

        log:printInfo("Workflow started: " + workflowId.toBalString() + " for sample: " + sampleData.id.toBalString());

        // Simulate starting the next step
        check self.processNextStep(workflowId);

        return workflow;
    }

    # Get workflow status
    # + workflowId - Workflow ID
    # + return - Workflow status or error
    public function getWorkflowStatus(string workflowId) returns FullWorkflowStatus|error {
        FullWorkflowStatus? workflow = self.workflows[workflowId];
        if workflow is FullWorkflowStatus {
            return workflow;
        }
        return error("Workflow not found");
    }

    # Get all active workflows
    # + return - Array of workflow statuses
    public function getActiveWorkflows() returns FullWorkflowStatus[] {
        FullWorkflowStatus[] activeWorkflows = [];
        foreach FullWorkflowStatus workflow in self.workflows {
            if workflow.status != "completed" && workflow.status != "failed" {
                activeWorkflows.push(workflow);
            }
        }
        return activeWorkflows;
    }

    # Process next step in workflow
    # + workflowId - Workflow ID
    # + return - Error if processing fails
    public function processNextStep(string workflowId) returns error? {
        FullWorkflowStatus? workflow = self.workflows[workflowId];
        if workflow is () {
            return error("Workflow not found");
        }

        // Find the next pending step
        foreach int i in 0 ..< workflow.steps.length() {
            ProcessingStep step = workflow.steps[i];
            if step.status == "pending" {
                // Start processing this step
                workflow.steps[i].status = "in_progress";
                workflow.steps[i].startTime = time:utcToString(time:utcNow());

                log:printInfo("Processing step: " + step.name + " for workflow: " + workflowId);

                // Simulate processing (in real implementation, this would call actual processing logic)
                check self.simulateStepProcessing(workflowId, i);
                break;
            }
        }

        self.workflows[workflowId] = workflow;
        return;
    }

    # Complete a workflow step
    # + workflowId - Workflow ID
    # + stepIndex - Step index
    # + result - Step result
    # + return - Error if completion fails
    public function completeStep(string workflowId, int stepIndex, json result) returns error? {
        FullWorkflowStatus? workflow = self.workflows[workflowId];
        if workflow is () {
            return error("Workflow not found");
        }

        if stepIndex >= workflow.steps.length() {
            return error("Invalid step index");
        }

        string timestamp = time:utcToString(time:utcNow());
        workflow.steps[stepIndex].status = "completed";
        workflow.steps[stepIndex].endTime = timestamp;
        workflow.steps[stepIndex].result = result;

        log:printInfo("Step completed: " + workflow.steps[stepIndex].name + " for workflow: " + workflowId);

        // Check if all steps are completed
        boolean allCompleted = true;
        foreach ProcessingStep step in workflow.steps {
            if step.status != "completed" {
                allCompleted = false;
                break;
            }
        }

        if allCompleted {
            workflow.status = "completed";
            workflow.endTime = timestamp;
            log:printInfo("Workflow completed: " + workflowId);
        } else {
            // Start next step
            check self.processNextStep(workflowId);
        }

        self.workflows[workflowId] = workflow;
        return;
    }

    # Fail a workflow step
    # + workflowId - Workflow ID
    # + stepIndex - Step index
    # + errorMessage - Error message
    # + return - Error if failing step fails
    public function failStep(string workflowId, int stepIndex, string errorMessage) returns error? {
        FullWorkflowStatus? workflow = self.workflows[workflowId];
        if workflow is () {
            return error("Workflow not found");
        }

        if stepIndex >= workflow.steps.length() {
            return error("Invalid step index");
        }

        string timestamp = time:utcToString(time:utcNow());
        workflow.steps[stepIndex].status = "failed";
        workflow.steps[stepIndex].endTime = timestamp;
        workflow.steps[stepIndex].errorMessage = errorMessage;

        workflow.status = "failed";
        workflow.endTime = timestamp;
        workflow.errorMessage = errorMessage;

        log:printError("Workflow failed: " + workflowId + " - " + errorMessage);

        self.workflows[workflowId] = workflow;
        return;
    }

    # Simulate step processing (replace with actual processing logic)
    # + workflowId - Workflow ID
    # + stepIndex - Step index
    # + return - Error if simulation fails
    private function simulateStepProcessing(string workflowId, int stepIndex) returns error? {
        FullWorkflowStatus? workflow = self.workflows[workflowId];
        if workflow is () {
            return error("Workflow not found");
        }

        ProcessingStep step = workflow.steps[stepIndex];

        // Simulate processing time and result based on step type
        json stepResult = {};
        match step.name {
            "sample_preparation" => {
                stepResult = {
                    "message": "Sample prepared successfully",
                    "preparedBy": "Tech001",
                    "preparationTime": time:utcToString(time:utcNow())
                };
            }
            "testing" => {
                stepResult = {
                    "message": "Tests completed",
                    "testsRun": ["CBC", "BMP", "Lipid Panel"],
                    "testingTime": time:utcToString(time:utcNow())
                };
            }
            "result_analysis" => {
                stepResult = {
                    "message": "Results analyzed",
                    "analyzer": "AutoAnalyzer3000",
                    "analysisTime": time:utcToString(time:utcNow())
                };
            }
            "report_generation" => {
                stepResult = {
                    "message": "Report generated",
                    "reportId": uuid:createType1AsString(),
                    "generationTime": time:utcToString(time:utcNow())
                };
            }
            _ => {
                stepResult = {
                    "message": "Step " + step.name + " completed",
                    "completionTime": time:utcToString(time:utcNow())
                };
            }
        }

        // Complete the step
        check self.completeStep(workflowId, stepIndex, stepResult);

        return;
    }

    # Get workflow statistics
    # + return - Workflow statistics
    public function getWorkflowStats() returns json {
        int totalWorkflows = self.workflows.length();
        int activeWorkflows = 0;
        int completedWorkflows = 0;
        int failedWorkflows = 0;

        foreach FullWorkflowStatus workflow in self.workflows {
            match workflow.status {
                "completed" => {
                    completedWorkflows += 1;
                }
                "failed" => {
                    failedWorkflows += 1;
                }
                _ => {
                    activeWorkflows += 1;
                }
            }
        }

        return {
            "totalWorkflows": totalWorkflows,
            "activeWorkflows": activeWorkflows,
            "completedWorkflows": completedWorkflows,
            "failedWorkflows": failedWorkflows,
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global lab workflow service instance
public final LabWorkflowService labWorkflowService = new;

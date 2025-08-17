import ballerina/log;
import ballerina/time;
import ballerina/uuid;

# Template Service for managing lab report templates
public class TemplateService {

    # In-memory storage for demo purposes (replace with database later)
    private map<ReportTemplate> templates = {};

    public function init() {
        // Initialize with some default templates
        self.createDefaultTemplates();
    }

    # Create a new template
    # + templateData - Template data without ID
    # + return - Created template or error
    public function createTemplate(ReportTemplateCreate templateData) returns ReportTemplate|error {
        string templateId = uuid:createType1AsString();
        string timestamp = time:utcToString(time:utcNow());

        ReportTemplate template = {
            id: templateId,
            name: templateData.name,
            description: templateData.description,
            testTypeId: templateData.testTypeId,
            sections: templateData.sections,
            isActive: templateData.isActive ?: true,
            createdBy: templateData.createdBy,
            createdAt: timestamp,
            updatedAt: timestamp
        };

        self.templates[templateId] = template;

        log:printInfo("Template created: " + templateId + " - " + template.name);

        return template;
    }

    # Get template by ID
    # + templateId - Template ID
    # + return - Template or error
    public function getTemplate(string templateId) returns ReportTemplate|error {
        ReportTemplate? template = self.templates[templateId];
        if template is ReportTemplate {
            return template;
        }
        return error("Template not found");
    }

    # Get templates by test type
    # + testTypeId - Test type ID
    # + return - Array of templates
    public function getTemplatesByTestType(string testTypeId) returns ReportTemplate[] {
        ReportTemplate[] testTypeTemplates = [];
        foreach ReportTemplate template in self.templates {
            if template.testTypeId == testTypeId && template.isActive {
                testTypeTemplates.push(template);
            }
        }
        return testTypeTemplates;
    }

    # Get all active templates
    # + return - Array of active templates
    public function getActiveTemplates() returns ReportTemplate[] {
        ReportTemplate[] activeTemplates = [];
        foreach ReportTemplate template in self.templates {
            if template.isActive {
                activeTemplates.push(template);
            }
        }
        return activeTemplates;
    }

    # Get all templates
    # + return - Array of all templates
    public function getAllTemplates() returns ReportTemplate[] {
        ReportTemplate[] allTemplates = [];
        foreach ReportTemplate template in self.templates {
            allTemplates.push(template);
        }
        return allTemplates;
    }

    # Update template
    # + templateId - Template ID
    # + updateData - Update data
    # + return - Updated template or error
    public function updateTemplate(string templateId, ReportTemplateUpdate updateData) returns ReportTemplate|error {
        ReportTemplate? template = self.templates[templateId];
        if template is () {
            return error("Template not found");
        }

        // Update fields if provided
        if updateData.name is string {
            template.name = updateData.name ?: template.name;
        }

        if updateData.description is string {
            template.description = updateData.description ?: template.description;
        }

        if updateData.sections is TemplateSection[] {
            template.sections = updateData.sections ?: template.sections;
        }

        if updateData.isActive is boolean {
            template.isActive = updateData.isActive ?: template.isActive;
        }

        template.updatedAt = time:utcToString(time:utcNow());

        self.templates[templateId] = template;

        log:printInfo("Template updated: " + templateId);

        return template;
    }

    # Deactivate template
    # + templateId - Template ID
    # + return - Updated template or error
    public function deactivateTemplate(string templateId) returns ReportTemplate|error {
        ReportTemplate? template = self.templates[templateId];
        if template is () {
            return error("Template not found");
        }

        template.isActive = false;
        template.updatedAt = time:utcToString(time:utcNow());

        self.templates[templateId] = template;

        log:printInfo("Template deactivated: " + templateId);

        return template;
    }

    # Activate template
    # + templateId - Template ID
    # + return - Updated template or error
    public function activateTemplate(string templateId) returns ReportTemplate|error {
        ReportTemplate? template = self.templates[templateId];
        if template is () {
            return error("Template not found");
        }

        template.isActive = true;
        template.updatedAt = time:utcToString(time:utcNow());

        self.templates[templateId] = template;

        log:printInfo("Template activated: " + templateId);

        return template;
    }

    # Generate report from template
    # + templateId - Template ID
    # + resultData - Lab result data
    # + return - Generated report content or error
    public function generateReportFromTemplate(string templateId, LabResult[] resultData) returns json|error {
        ReportTemplate template = check self.getTemplate(templateId);

        if !template.isActive {
            return error("Template is not active");
        }

        json reportContent = {
            "templateId": templateId,
            "templateName": template.name,
            "generatedAt": time:utcToString(time:utcNow()),
            "sections": []
        };

        json[] sectionContents = [];

        foreach TemplateSection section in template.sections {
            json sectionContent = {
                "sectionId": section.id,
                "name": section.name,
                "type": section.sectionType,
                "order": section.orderIndex,
                "content": self.generateSectionContent(section, resultData)
            };

            sectionContents.push(sectionContent);
        }

        reportContent = {
            "templateId": templateId,
            "templateName": template.name,
            "generatedAt": time:utcToString(time:utcNow()),
            "sections": sectionContents
        };

        log:printInfo("Report generated from template: " + templateId);

        return reportContent;
    }

    # Generate content for a template section
    # + section - Template section
    # + resultData - Lab result data
    # + return - Generated section content
    private function generateSectionContent(TemplateSection section, LabResult[] resultData) returns json {
        match section.sectionType {
            "header" => {
                map<json> contentMap = <map<json>>section.content;
                return {
                    "title": contentMap["title"],
                    "subtitle": "Lab Report",
                    "generatedAt": time:utcToString(time:utcNow())
                };
            }
            "patient_info" => {
                return {
                    "patientId": resultData.length() > 0 ? "Patient-001" : "Unknown",
                    "reportDate": time:utcToString(time:utcNow()),
                    "testCount": resultData.length()
                };
            }
            "test_results" => {
                json[] results = [];
                foreach LabResult result in resultData {
                    json resultContent = {
                        "testTypeId": <string>result["testTypeId"],
                        "results": <json>result["results"],
                        "normalRanges": <json>result["normalRanges"],
                        "status": result.status,
                        "notes": <string>result["notes"]
                    };
                    results.push(resultContent);
                }
                return {
                    "results": results,
                    "totalTests": resultData.length()
                };
            }
            "interpretation" => {
                return {
                    "overallStatus": "Normal",
                    "criticalFindings": [],
                    "recommendations": [
                        "Follow up with physician for detailed discussion",
                        "Maintain regular health checkups"
                    ]
                };
            }
            "footer" => {
                return {
                    "reportGeneratedBy": "MediLink Lab System",
                    "contactInfo": "Contact: lab@medilink.com",
                    "disclaimer": "This report is generated automatically and should be reviewed by a qualified healthcare professional."
                };
            }
            _ => {
                return section.content;
            }
        }
    }

    # Create default templates
    private function createDefaultTemplates() {
        // Basic Lab Report Template
        ReportTemplateCreate basicTemplate = {
            name: "Basic Lab Report",
            description: "Standard template for general lab reports",
            testTypeId: "general",
            sections: [
                {
                    id: "header",
                    name: "Report Header",
                    sectionType: "header",
                    orderIndex: 1,
                    content: {
                        "title": "Laboratory Report",
                        "logo": "medilink_logo.png"
                    }
                },
                {
                    id: "patient_info",
                    name: "Patient Information",
                    sectionType: "patient_info",
                    orderIndex: 2,
                    content: {
                        "fields": ["patientId", "testDate", "sampleId"]
                    }
                },
                {
                    id: "test_results",
                    name: "Test Results",
                    sectionType: "test_results",
                    orderIndex: 3,
                    content: {
                        "showNormalRanges": true,
                        "highlightAbnormal": true
                    }
                },
                {
                    id: "interpretation",
                    name: "Clinical Interpretation",
                    sectionType: "interpretation",
                    orderIndex: 4,
                    content: {
                        "includeRecommendations": true
                    }
                },
                {
                    id: "footer",
                    name: "Report Footer",
                    sectionType: "footer",
                    orderIndex: 5,
                    content: {
                        "includeDisclaimer": true,
                        "contactInfo": true
                    }
                }
            ],
            isActive: true,
            createdBy: "System"
        };

        ReportTemplate|error basicResult = self.createTemplate(basicTemplate);
        if basicResult is error {
            log:printError("Failed to create basic template: " + basicResult.message());
        }

        // Blood Work Template
        ReportTemplateCreate bloodTemplate = {
            name: "Blood Work Report",
            description: "Specialized template for blood test reports",
            testTypeId: "blood_work",
            sections: [
                {
                    id: "header",
                    name: "Report Header",
                    sectionType: "header",
                    orderIndex: 1,
                    content: {
                        "title": "Blood Work Analysis Report"
                    }
                },
                {
                    id: "patient_info",
                    name: "Patient Information",
                    sectionType: "patient_info",
                    orderIndex: 2,
                    content: {
                        "fields": ["patientId", "testDate", "fastingStatus"]
                    }
                },
                {
                    id: "test_results",
                    name: "Blood Test Results",
                    sectionType: "test_results",
                    orderIndex: 3,
                    content: {
                        "groupByCategory": true,
                        "showTrends": true
                    }
                },
                {
                    id: "interpretation",
                    name: "Clinical Interpretation",
                    sectionType: "interpretation",
                    orderIndex: 4,
                    content: {
                        "includeRiskFactors": true
                    }
                }
            ],
            isActive: true,
            createdBy: "System"
        };

        ReportTemplate|error bloodResult = self.createTemplate(bloodTemplate);
        if bloodResult is error {
            log:printError("Failed to create blood template: " + bloodResult.message());
        }

        log:printInfo("Default templates created successfully");
    }

    # Get template statistics
    # + return - Template statistics
    public function getTemplateStats() returns json {
        int totalTemplates = self.templates.length();
        int activeTemplates = 0;
        int inactiveTemplates = 0;

        foreach ReportTemplate template in self.templates {
            if template.isActive {
                activeTemplates += 1;
            } else {
                inactiveTemplates += 1;
            }
        }

        return {
            "totalTemplates": totalTemplates,
            "activeTemplates": activeTemplates,
            "inactiveTemplates": inactiveTemplates,
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}

# Global template service instance
public final TemplateService templateService = new;

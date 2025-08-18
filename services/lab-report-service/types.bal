import ballerina/sql;
import ballerina/time;

// Test Type entity - mat// Lab Sample record for database operations
public type LabSampleRecord record {
    int id?;
    string labId;
    string barcode;
    int testTypeId;
    string sampleType;
    string? volume;
    string? container;
    string patientId;
    time:Civil? createdAt;
    time:Civil? expectedTime;
    time:Civil? updatedAt;
    string status;
    string? priority;
    string? notes;
};

// Test Types
public type TestType record {
    int id?;
    string value;
    string label;
    string category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
    json? basicFields;
    time:Civil? createdAt;
    time:Civil? updatedAt;
};

// Test Type creation payload - excludes auto-generated fields
public type TestTypeCreate record {
    string value;
    string label;
    string category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
};

// Test Type update payload - excludes auto-generated fields
public type TestTypeUpdate record {
    string? value;
    string? label;
    string? category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
    json? basicFields;
};

// Test Type record for database operations
// public type TestTypeRecord record {
//     int id?;
//     string value;
//     string label;
//     string category;
//     string? parser_class;
//     string? parser_module;
//     json? report_fields;
//     json? reference_ranges;
//     json? basic_fields;
//     time:Civil? created_at;
//     time:Civil? updated_at;
// };

// Lab Sample entity - matches TypeScript LabSample
public type LabSample record {
    string id?;
    string labId;
    string barcode;
    int testTypeId;
    string sampleType;
    string? volume;
    string? container;
    string patientId;
    time:Civil? createdAt;
    time:Civil? expectedTime;
    time:Civil? updatedAt;
    string status;
    string? priority;
    string? notes;
};

// Lab Result entity - matches TypeScript LabResult
public type LabResult record {
    int id?;
    int labSampleId;
    string? reportUrl;
    json? extractedData;
    time:Civil? createdAt;
    time:Civil? updatedAt;
    string status;
    string? reviewNotes;
    int? reviewedBy;
    time:Civil? reviewedAt;
    boolean? isAnomaly;
    decimal? confidenceScore;
};

// Lab Result record for database operations
public type LabResultRecord record {
    int id?;
    int lab_sample_id;
    string? report_url;
    json? extracted_data;
    time:Civil? created_at;
    time:Civil? updated_at;
    string status;
    string? review_notes;
    int? reviewed_by;
    time:Civil? reviewed_at;
    boolean? is_anomaly;
    decimal? confidence_score;
};

// Request/Response types for API operations
public type CreateTestTypeRequest record {
    string value;
    string label;
    string category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
    json? basicFields;
};

public type UpdateTestTypeRequest record {
    string? value;
    string? label;
    string? category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
    json? basicFields;
};

public type CreateLabSampleRequest record {
    string labId;
    string barcode;
    int testTypeId;
    string sampleType;
    decimal? volume;
    string? container;
    int? patientId;
    string? collectionDate;
    string? receivedDate;
    string? status;
    string? notes;
};

public type UpdateLabSampleRequest record {
    string? labId;
    string? barcode;
    int? testTypeId;
    string? sampleType;
    decimal? volume;
    string? container;
    int? patientId;
    string? collectionDate;
    string? receivedDate;
    string? status;
    string? notes;
};

public type CreateLabResultRequest record {
    int labSampleId;
    string? reportUrl;
    json? extractedData;
    string? status;
    string? reviewNotes;
    int? reviewedBy;
    boolean? isAnomaly;
    decimal? confidenceScore;
};

public type UpdateLabResultRequest record {
    string? reportUrl;
    json? extractedData;
    string? status;
    string? reviewNotes;
    int? reviewedBy;
    boolean? isAnomaly;
    decimal? confidenceScore;
};

// Response types
public type TestTypeResponse record {
    int id;
    string value;
    string label;
    string category;
    string? parserClass;
    string? parserModule;
    json? reportFields;
    json? referenceRanges;
    json? basicFields;
    string? createdAt;
    string? updatedAt;
};

public type LabSampleResponse record {
    int id;
    string labId;
    string barcode;
    int testTypeId;
    string sampleType;
    decimal? volume;
    string? container;
    int? patientId;
    string? collectionDate;
    string? receivedDate;
    string status;
    string? notes;
    string? createdAt;
    string? updatedAt;
};

public type LabResultResponse record {
    int id;
    int labSampleId;
    string? reportUrl;
    json? extractedData;
    string? createdAt;
    string? updatedAt;
    string status;
    string? reviewNotes;
    int? reviewedBy;
    string? reviewedAt;
    boolean? isAnomaly;
    decimal? confidenceScore;
};

// Error response type
public type ErrorResponse record {
    string message;
    string? code;
    string? details;
};

// Generic API response type
public type ApiResponse record {
    boolean success;
    string message;
    json? data;
    ErrorResponse? 'error;
};

// Pagination types
public type PaginationQuery record {
    int page = 1;
    int pageSize = 10;
    string? sortBy;
    string? sortOrder;
    string? search;
};

public type PaginatedResponse record {
    json[] data;
    int total;
    int page;
    int pageSize;
    int totalPages;
    boolean hasNext;
    boolean hasPrev;
};

// Database connection configuration
public type DatabaseConfig record {
    string host;
    int port;
    string name;
    string username;
    string password;
    sql:ConnectionPool? connectionPool;
};

// Service configuration
public type ServiceConfig record {
    int port;
    string host;
    DatabaseConfig database;
    boolean enableCors;
    string[] allowedOrigins;
};

# Processing step in workflow
public type ProcessingStep record {
    string name;
    string status;
    string startTime;
    string? endTime;
    json? result;
    string? errorMessage;
};

# Workflow status structure
public type FullWorkflowStatus record {
    string id;
    string status;
    string sampleId;
    ProcessingStep[] steps;
    string startTime;
    string? endTime;
    string? errorMessage;
};

# Lab result creation record
public type LabResultCreate record {
    string sampleId;
    string testTypeId;
    json results;
    json? normalRanges?;
    string? reviewedBy?;
    string? notes?;
    string? resultDate?;
    string? resultValue?;
};

# Lab result update record
public type LabResultUpdate record {
    json? results?;
    json? normalRanges?;
    string? status?;
    string? reviewedBy?;
    string? notes?;
};

# Lab report record
public type LabReport record {
    string id;
    string sampleId;
    string? templateId?;
    json content;
    string status;
    string generatedBy;
    string generatedAt;
    string? finalizedBy?;
    string? finalizedAt?;
    string createdAt;
    string updatedAt;
};

# Record type for creating a new lab sample
public type LabSampleCreate record {
    string labId;
    string barcode;
    int testTypeId;
    string sampleType = "blood";
    string? volume;
    string? container;
    string patientId;
    string status = "pending";
    string? priority;
    string? notes;
    string? expectedTime;
};

// Lab Sample update payload
public type LabSampleUpdate record {
    string? labId;
    string? barcode;
    int? testTypeId;
    string? sampleType;
    string? volume;
    string? container;
    string? patientId;
    string? status;
    string? priority;
    string? notes;
    string? expectedTime;
};

# Record type for lab sample
// public type LabSample record {
//     string id;
//     string patientId;
//     string testTypeId;
//     string collectionDate;
//     string status;
//     string priority;
//     string? notes?;
//     string collectedBy;
//     string? processedBy?;
//     string? processedAt?;
//     string? completedAt?;
//     string createdAt;
//     string updatedAt;
// };

# Record type for creating lab results
// public type LabResultCreate record {
//     string testTypeId;
//     json results;
//     json? normalRanges?;
//     string? reviewedBy?;
//     string? notes?;
//     string? resultDate?;
//     string? resultValue?;
// };

# Record type for full lab results
public type FullLabResult record {
    string id;
    string sampleId;
    string testTypeId;
    json results;
    json? normalRanges?;
    string status;
    string? reviewedBy?;
    string? reviewedAt?;
    string? completedAt?;
    string? notes?;
    string? resultDate?;
    string? resultValue?;
    string createdAt;
    string updatedAt;
};

# Workflow status type
public type WorkflowStatus record {
    string id;
    string status;
    string message;
};

# Template Section type
public type TemplateSection record {
    string id;
    string name;
    string sectionType;
    int orderIndex;
    json content;
};

# Report Template type
public type ReportTemplate record {
    string id;
    string name;
    string description;
    string testTypeId;
    TemplateSection[] sections;
    boolean isActive;
    string createdBy;
    string createdAt;
    string updatedAt;
};

# Report Template Create type
public type ReportTemplateCreate record {
    string name;
    string description;
    string testTypeId;
    TemplateSection[] sections;
    boolean? isActive;
    string createdBy;
};

# Report Template Update type
public type ReportTemplateUpdate record {
    string? name;
    string? description;
    TemplateSection[]? sections;
    boolean? isActive;
};

type TestTypeRecord record {|
    int id;
    string value;
    string label;
    string category;
    string? parser_class;
    string? parser_module;
    string? report_fields;
    string? reference_ranges;
    string? basic_fields;
    time:Civil? created_at;
    time:Civil? updated_at;
|};

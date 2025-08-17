# Lab Report Service Data Types

# Test Type entity
public type TestType record {|
    # Unique identifier for the test type
    string id;
    # Name of the test type
    string name;
    # Description of the test type
    string description;
    # Test category
    string category;
    # Parser configuration for extracting data
    json parserConfig?;
    # Reference ranges for the test
    json referenceRanges?;
    # Units of measurement
    string units?;
    # Creation timestamp
    string createdAt;
    # Last update timestamp
    string updatedAt;
|};

# Lab Sample entity
public type LabSample record {|
    # Unique identifier for the sample
    string id;
    # Patient ID associated with the sample
    string patientId;
    # Sample type (blood, urine, etc.)
    string sampleType;
    # Sample collection date
    string collectionDate;
    # Sample status (collected, processing, completed)
    string status;
    # Barcode or sample identifier
    string barcode?;
    # Collection site/location
    string collectionSite?;
    # Special handling instructions
    string handlingInstructions?;
    # Creation timestamp
    string createdAt;
    # Last update timestamp
    string updatedAt;
|};

# Lab Result entity
public type LabResult record {|
    # Unique identifier for the result
    string id;
    # Sample ID associated with the result
    string sampleId;
    # Test type ID
    string testTypeId;
    # Test result value
    string|decimal|int resultValue;
    # Result units
    string units?;
    # Reference range for this result
    string referenceRange?;
    # Result status (normal, abnormal, critical)
    string status;
    # Comments or notes about the result
    string comments?;
    # Result interpretation
    string interpretation?;
    # Technician who performed the test
    string technician?;
    # Result date
    string resultDate;
    # Encrypted data flag
    boolean isEncrypted?;
    # Creation timestamp
    string createdAt;
    # Last update timestamp
    string updatedAt;
|};

# Lab Report DTO
public type LabReportDto record {|
    # Report ID
    string id;
    # Patient information
    PatientInfo patient;
    # Sample information
    LabSample sample;
    # Test results
    LabResult[] results;
    # Report status
    string status;
    # Report generation date
    string reportDate;
    # Doctor information
    DoctorInfo doctor?;
    # Additional metadata
    json metadata?;
|};

# Patient information
public type PatientInfo record {|
    # Patient ID
    string id;
    # Patient name
    string name;
    # Date of birth
    string dateOfBirth;
    # Gender
    string gender;
    # Contact information
    ContactInfo contact?;
|};

# Contact information
public type ContactInfo record {|
    # Phone number
    string phone?;
    # Email address
    string email?;
    # Address
    AddressInfo address?;
|};

# Address information
public type AddressInfo record {|
    # Street address
    string street?;
    # City
    string city?;
    # State or province
    string state?;
    # Postal code
    string postalCode?;
    # Country
    string country?;
|};

# Doctor information
public type DoctorInfo record {|
    # Doctor ID
    string id;
    # Doctor name
    string name;
    # Specialization
    string specialization?;
    # License number
    string licenseNumber?;
    # Contact information
    ContactInfo contact?;
|};

# Workflow status
public type WorkflowStatus record {|
    # Workflow ID
    string id;
    # Current status
    string status;
    # Sample ID being processed
    string sampleId;
    # Processing steps
    ProcessingStep[] steps;
    # Start time
    string startTime;
    # End time (if completed)
    string endTime?;
    # Error information (if any)
    string errorMessage?;
|};

# Processing step
public type ProcessingStep record {|
    # Step name
    string name;
    # Step status
    string status;
    # Start time
    string startTime;
    # End time (if completed)
    string endTime?;
    # Step result or output
    json result?;
    # Error message (if failed)
    string errorMessage?;
|};

# Template information
public type Template record {|
    # Template ID
    string id;
    # Template name
    string name;
    # Template description
    string description;
    # Template content/structure
    json content;
    # Test types this template supports
    string[] supportedTestTypes;
    # Template version
    string version;
    # Creation timestamp
    string createdAt;
    # Last update timestamp
    string updatedAt;
|};

# API Response wrapper
public type ApiResponse record {|
    # Response message
    string message;
    # Response data
    anydata data?;
    # Error information
    string 'error?;
    # Timestamp
    string timestamp;
    # Pagination info (for list endpoints)
    PaginationInfo pagination?;
|};

# Pagination information
public type PaginationInfo record {|
    # Current page number
    int page;
    # Number of items per page
    int pageSize;
    # Total number of items
    int totalItems;
    # Total number of pages
    int totalPages;
    # Has next page
    boolean hasNext;
    # Has previous page
    boolean hasPrevious;
|};

# Event data for Kafka
public type LabSampleCreatedEvent record {|
    # Event ID
    string eventId;
    # Sample ID
    string sampleId;
    # Patient ID
    string patientId;
    # Event timestamp
    string timestamp;
    # Sample data
    LabSample sampleData;
    # Event metadata
    json metadata?;
|};

# File upload information
public type FileUploadInfo record {|
    # File ID
    string id;
    # Original filename
    string filename;
    # File size in bytes
    int size;
    # MIME type
    string mimeType;
    # Upload timestamp
    string uploadedAt;
    # File path or URL
    string path;
    # Associated sample ID
    string sampleId?;
    # Processing status
    string processingStatus;
|};

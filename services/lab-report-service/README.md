# Lab Report Service

A comprehensive Ballerina-based microservice for managing laboratory reports, test types, samples, results, and workflows in the MediLink healthcare system.

## Overview

The Lab Report Service handles:

- **Test Types**: Management of laboratory test configurations
- **Lab Samples**: Sample tracking and status management
- **Lab Results**: Result processing and review workflow
- **Lab Reports**: Report generation and finalization
- **Templates**: Report template management
- **Workflows**: Automated processing workflows

## Features

- 🔬 Complete lab sample lifecycle management
- 📊 Automated report processing using Python-based parsers
- 📋 Template-based report generation
- 🔄 Workflow automation for sample processing
- 📈 Statistics and analytics endpoints
- 🔍 Advanced filtering and search capabilities
- 📄 File upload support for report processing

## Getting Started

### Configuration

The service uses configurable parameters:

- `servicePort`: Service port (default: 3004)
- Database connection parameters (configured in `database.bal`)

### Running the Service

```bash
bal run
```

The service will start on `http://localhost:3004`

## API Documentation

### Health Check

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "service": "lab-report-service",
  "timestamp": "2025-08-31T10:30:00Z",
  "version": "1.0.0"
}
```

## Main API Endpoints

### 1. Test Types Management

#### Create Test Type

```http
POST /testtypes
Content-Type: application/json

{
  "value": "FBC",
  "label": "Full Blood Count",
  "category": "Hematology",
  "parserClass": "FBCParser",
  "parserModule": "parser_fbc_report",
  "reportFields": {
    "hemoglobin": "Hemoglobin",
    "wbc": "White Blood Cells",
    "rbc": "Red Blood Cells",
    "platelets": "Platelets"
  },
  "referenceRanges": {
    "hemoglobin": {
      "male": {"min": 13.5, "max": 17.5, "unit": "g/dL"},
      "female": {"min": 12.0, "max": 15.5, "unit": "g/dL"}
    },
    "wbc": {"min": 4.0, "max": 11.0, "unit": "×10³/μL"},
    "platelets": {"min": 150, "max": 450, "unit": "×10³/μL"}
  }
}
```

**Response:**

```json
{
  "id": 1,
  "value": "FBC",
  "label": "Full Blood Count",
  "category": "Hematology",
  "parserClass": "FBCParser",
  "parserModule": "parser_fbc_report",
  "reportFields": {
    /* ... */
  },
  "referenceRanges": {
    /* ... */
  },
  "createdAt": "2025-08-31T10:30:00Z",
  "updatedAt": "2025-08-31T10:30:00Z"
}
```

#### Get All Test Types

```http
GET /testtypes
```

#### Get Test Type by ID

```http
GET /testtypes/{id}
```

#### Update Test Type

```http
PUT /testtypes/{id}
Content-Type: application/json

{
  "label": "Complete Blood Count",
  "reportFields": {
    "hemoglobin": "Hemoglobin Level",
    "hematocrit": "Hematocrit"
  }
}
```

### 2. Lab Samples Management

#### Create Lab Sample

```http
POST /samples
Content-Type: application/json

{
  "labId": "LAB-2025-001",
  "barcode": "BC123456789",
  "testTypeId": 1,
  "sampleType": "Blood",
  "volume": "5ml",
  "container": "EDTA Tube",
  "patientId": "PAT-001",
  "priority": "routine",
  "notes": "Fasting sample"
}
```

**Response:**

```json
{
  "id": "sample-uuid-123",
  "labId": "LAB-2025-001",
  "barcode": "BC123456789",
  "testTypeId": 1,
  "sampleType": "Blood",
  "volume": "5ml",
  "container": "EDTA Tube",
  "patientId": "PAT-001",
  "status": "received",
  "priority": "routine",
  "notes": "Fasting sample",
  "createdAt": "2025-08-31T10:30:00Z",
  "updatedAt": "2025-08-31T10:30:00Z"
}
```

#### Get All Samples

```http
GET /samples
```

#### Get Sample by ID

```http
GET /samples/{id}
```

#### Get Samples by Patient

```http
GET /samples/patient/{patientId}
```

#### Get Samples by Status

```http
GET /samples/status/{status}
```

Available statuses: `received`, `processing`, `completed`, `reviewed`, `reported`

#### Update Sample Status

```http
PUT /samples/{id}/status
Content-Type: application/json

{
  "status": "processing",
  "notes": "Sample processing started"
}
```

#### Process Sample

```http
PUT /samples/{id}/process
Content-Type: application/json

{
  "processedBy": "tech-001"
}
```

#### Complete Sample with Results

```http
PUT /samples/{id}/complete
Content-Type: application/json

{
  "labSampleId": 1,
  "extractedData": {
    "hemoglobin": 14.2,
    "wbc": 7.5,
    "rbc": 4.8,
    "platelets": 320
  },
  "status": "completed"
}
```

### 3. Process Lab Report (File Upload)

This is one of the most important endpoints for processing lab reports from uploaded files.

```http
POST /workflows/samples/{sampleId}/process-report
Content-Type: multipart/form-data

Form Fields:
- reportFilePath: [PDF/Image file]
- processedBy: "tech-001"
```

**Example using curl:**

```bash
curl -X POST "http://localhost:3004/workflows/samples/sample-uuid-123/process-report" \
  -F "reportFilePath=@/path/to/lab-report.pdf" \
  -F "processedBy=tech-001"
```

**Example using JavaScript/Fetch:**

```javascript
const formData = new FormData();
formData.append("reportFilePath", fileInput.files[0]);
formData.append("processedBy", "tech-001");

const response = await fetch(
  `http://localhost:3004/workflows/samples/${sampleId}/process-report`,
  {
    method: "POST",
    body: formData,
  }
);

const result = await response.json();
```

**Response:**

```json
{
  "sampleId": "sample-uuid-123",
  "status": "success",
  "extractedData": {
    "hemoglobin": 14.2,
    "wbc": 7500,
    "rbc": 4.8,
    "platelets": 320000,
    "patient": {
      "name": "John Doe",
      "age": 35,
      "gender": "Male"
    }
  },
  "confidence": 0.95,
  "processedAt": "2025-08-31T10:30:00Z",
  "processedBy": "tech-001",
  "filePath": "temp_uploads/fbc_report_123.pdf"
}
```

### 4. Lab Results Management

#### Get All Results

```http
GET /results
```

#### Create Result

```http
POST /results
Content-Type: application/json

{
  "labSampleId": 1,
  "extractedData": {
    "hemoglobin": 14.2,
    "wbc": 7.5,
    "platelets": 320
  },
  "status": "pending_review"
}
```

#### Get Results by Sample

```http
GET /results/sample/{sampleId}
```

#### Review Result

```http
PUT /results/{id}/review
Content-Type: application/json

{
  "reviewedBy": "doctor-001",
  "notes": "Values within normal range"
}
```

### 5. Report Generation

#### Generate Report

```http
POST /reports/generate
Content-Type: application/json

{
  "sampleId": "sample-uuid-123",
  "templateId": "template-001",
  "generatedBy": "system"
}
```

#### Get Reports by Sample

```http
GET /reports/sample/{sampleId}
```

#### Finalize Report

```http
PUT /reports/{id}/finalize
Content-Type: application/json

{
  "finalizedBy": "doctor-001"
}
```

### 6. Templates Management

#### Get All Templates

```http
GET /templates
```

#### Create Template

```http
POST /templates
Content-Type: application/json

{
  "name": "FBC Report Template",
  "testTypeId": 1,
  "templateData": {
    "sections": [
      {
        "title": "Hematology Results",
        "fields": ["hemoglobin", "wbc", "rbc", "platelets"]
      }
    ]
  },
  "isActive": true
}
```

### 7. Workflow Management

#### Get Active Workflows

```http
GET /workflows/active
```

#### Get Workflow Status

```http
GET /workflows/{id}
```

#### Process Next Workflow Step

```http
POST /workflows/{id}/process
```

#### Get Processing Statistics

```http
GET /workflows/processing/stats
```

## Sample Status Flow

1. **received** → Sample received in lab
2. **processing** → Sample being processed
3. **completed** → Processing completed, awaiting review
4. **reviewed** → Results reviewed by technician
5. **reported** → Final report generated

## Error Handling

The API returns standard HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `404` - Not Found
- `500` - Internal Server Error

Error responses include:

```json
{
  "error": "Error message",
  "details": "Additional details about the error"
}
```

## File Upload Support

The service supports uploading lab reports in the following formats:

- PDF files
- Image files (JPEG, PNG, etc.)

Files are temporarily stored in the `temp_uploads` directory and processed using Python-based parsers.

## Python Integration

The service integrates with Python scripts for report processing:

- `parser_factory.py` - Factory for creating appropriate parsers
- `parser_fbc_report.py` - FBC report parser
- `parser_lab_report.py` - Generic lab report parser
- `extractor.py` - Data extraction utilities

## Statistics Endpoints

Get insights about your lab operations:

- `/samples/stats` - Sample statistics
- `/results/stats` - Result statistics
- `/workflows/stats` - Workflow statistics
- `/templates/stats` - Template usage statistics

## Development

### Project Structure

```
lab-report-service/
├── main.bal                    # Main service file
├── types.bal                   # Type definitions
├── database.bal                # Database operations
├── sample-service.bal          # Sample management
├── result-service.bal          # Result management
├── template-service.bal        # Template management
├── workflow-service.bal        # Workflow management
├── report-processing-service.bal # Report processing
├── python/                     # Python parsers
│   ├── parser_factory.py
│   ├── parser_fbc_report.py
│   └── ...
└── temp_uploads/              # Temporary file storage
```

### Testing

Use the included Postman collection for testing:

- `Lab_Report_Service_Postman_Collection.json`
- `Lab_Report_Service_Environment.postman_environment.json`

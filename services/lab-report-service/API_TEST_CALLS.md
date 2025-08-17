# Lab Report Service API Test Calls

Base URL: `http://localhost:3004`

## 1. Health Check

```bash
# Check service health
curl -X GET "http://localhost:3004/health"
```

## 2. Test Types Management

```bash
# Get all test types
curl -X GET "http://localhost:3004/testtypes"

# Create a new test type
curl -X POST "http://localhost:3004/testtypes" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "tt001",
    "name": "Complete Blood Count",
    "description": "Full blood panel including RBC, WBC, platelets",
    "category": "Hematology",
    "units": "cells/μL",
    "parserConfig": {
      "format": "standard",
      "fields": ["rbc", "wbc", "platelets", "hemoglobin"]
    },
    "referenceRanges": {
      "rbc": {"min": 4.5, "max": 5.5, "unit": "million/μL"},
      "wbc": {"min": 4000, "max": 11000, "unit": "cells/μL"},
      "platelets": {"min": 150000, "max": 450000, "unit": "cells/μL"}
    },
    "createdAt": "2025-08-17T10:00:00Z",
    "updatedAt": "2025-08-17T10:00:00Z"
  }'

# Update a test type
curl -X PUT "http://localhost:3004/testtypes/tt001" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "tt001",
    "name": "Complete Blood Count - Updated",
    "description": "Full blood panel including RBC, WBC, platelets - Updated",
    "category": "Hematology",
    "units": "cells/μL",
    "createdAt": "2025-08-17T10:00:00Z",
    "updatedAt": "2025-08-17T11:00:00Z"
  }'

# Delete a test type
curl -X DELETE "http://localhost:3004/testtypes/tt001"
```

## 3. Lab Samples Management

```bash
# Get all samples
curl -X GET "http://localhost:3004/samples"

# Create a new lab sample
curl -X POST "http://localhost:3004/samples" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "patient123",
    "testTypeId": "tt001",
    "collectionDate": "2025-08-17T09:30:00Z",
    "priority": "normal",
    "notes": "Patient fasting for 12 hours",
    "collectedBy": "nurse001"
  }'

# Get sample by ID (replace with actual ID from creation response)
curl -X GET "http://localhost:3004/samples/SAMPLE_ID"

# Get samples by patient
curl -X GET "http://localhost:3004/samples/patient/patient123"

# Get samples by status
curl -X GET "http://localhost:3004/samples/status/collected"

# Update sample status
curl -X PUT "http://localhost:3004/samples/SAMPLE_ID/status" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "processing",
    "notes": "Sample received in lab"
  }'

# Process sample
curl -X PUT "http://localhost:3004/samples/SAMPLE_ID/process" \
  -H "Content-Type: application/json" \
  -d '{
    "processedBy": "lab_tech001"
  }'

# Complete sample with results
curl -X PUT "http://localhost:3004/samples/SAMPLE_ID/complete" \
  -H "Content-Type: application/json" \
  -d '{
    "sampleId": "SAMPLE_ID",
    "testTypeId": "tt001",
    "results": {
      "rbc": 4.8,
      "wbc": 7500,
      "platelets": 250000,
      "hemoglobin": 14.2
    },
    "normalRanges": {
      "rbc": {"min": 4.5, "max": 5.5},
      "wbc": {"min": 4000, "max": 11000},
      "platelets": {"min": 150000, "max": 450000}
    },
    "resultDate": "2025-08-17T14:30:00Z",
    "resultValue": "Normal values within reference ranges",
    "reviewedBy": "doctor001",
    "notes": "All parameters within normal limits"
  }'

# Get sample with results
curl -X GET "http://localhost:3004/samples/SAMPLE_ID/results"

# Get sample statistics
curl -X GET "http://localhost:3004/samples/stats"

# Delete sample
curl -X DELETE "http://localhost:3004/samples/SAMPLE_ID"
```

## 4. Lab Results Management

```bash
# Get all results
curl -X GET "http://localhost:3004/results"

# Create a new result
curl -X POST "http://localhost:3004/results" \
  -H "Content-Type: application/json" \
  -d '{
    "sampleId": "SAMPLE_ID",
    "testTypeId": "tt001",
    "results": {
      "rbc": 4.8,
      "wbc": 7500,
      "platelets": 250000,
      "hemoglobin": 14.2
    },
    "normalRanges": {
      "rbc": {"min": 4.5, "max": 5.5},
      "wbc": {"min": 4000, "max": 11000},
      "platelets": {"min": 150000, "max": 450000}
    },
    "resultDate": "2025-08-17T14:30:00Z",
    "resultValue": "Normal values within reference ranges",
    "reviewedBy": "doctor001",
    "notes": "All parameters within normal limits"
  }'

# Get result by ID
curl -X GET "http://localhost:3004/results/RESULT_ID"

# Get results by sample
curl -X GET "http://localhost:3004/results/sample/SAMPLE_ID"

# Get results by status
curl -X GET "http://localhost:3004/results/status/pending_review"

# Update result
curl -X PUT "http://localhost:3004/results/RESULT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "notes": "Updated analysis notes",
    "status": "reviewed"
  }'

# Review result
curl -X PUT "http://localhost:3004/results/RESULT_ID/review" \
  -H "Content-Type: application/json" \
  -d '{
    "reviewedBy": "senior_doctor001",
    "notes": "Reviewed and approved - all normal"
  }'

# Get result statistics
curl -X GET "http://localhost:3004/results/stats"
```

## 5. Lab Reports Management

```bash
# Get all reports
curl -X GET "http://localhost:3004/reports"

# Generate a new report
curl -X POST "http://localhost:3004/reports/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "sampleId": "SAMPLE_ID",
    "templateId": "template001",
    "generatedBy": "doctor001"
  }'

# Get report by ID
curl -X GET "http://localhost:3004/reports/REPORT_ID"

# Get reports by sample
curl -X GET "http://localhost:3004/reports/sample/SAMPLE_ID"

# Finalize report
curl -X PUT "http://localhost:3004/reports/REPORT_ID/finalize" \
  -H "Content-Type: application/json" \
  -d '{
    "finalizedBy": "chief_doctor001"
  }'
```

## 6. Templates Management

```bash
# Get all templates
curl -X GET "http://localhost:3004/templates"

# Get active templates
curl -X GET "http://localhost:3004/templates/active"

# Create a new template
curl -X POST "http://localhost:3004/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Blood Test Report Template",
    "description": "Standard template for blood test reports",
    "sections": [
      {
        "id": "header",
        "title": "Patient Information",
        "content": "Patient: {{patient.name}}\nDate: {{test.date}}",
        "orderIndex": 1
      },
      {
        "id": "results",
        "title": "Test Results",
        "content": "{{test.results}}",
        "orderIndex": 2
      },
      {
        "id": "conclusion",
        "title": "Medical Opinion",
        "content": "{{doctor.notes}}",
        "orderIndex": 3
      }
    ],
    "category": "blood_tests"
  }'

# Get template by ID
curl -X GET "http://localhost:3004/templates/TEMPLATE_ID"

# Get templates by test type
curl -X GET "http://localhost:3004/templates/testtype/tt001"

# Update template
curl -X PUT "http://localhost:3004/templates/TEMPLATE_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Blood Test Report Template",
    "description": "Updated standard template for blood test reports"
  }'

# Activate template
curl -X PUT "http://localhost:3004/templates/TEMPLATE_ID/activate"

# Deactivate template
curl -X PUT "http://localhost:3004/templates/TEMPLATE_ID/deactivate"

# Generate report from template
curl -X POST "http://localhost:3004/templates/TEMPLATE_ID/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "resultData": []
  }'

# Get template statistics
curl -X GET "http://localhost:3004/templates/stats"
```

## 7. Workflows Management

```bash
# Get active workflows
curl -X GET "http://localhost:3004/workflows/active"

# Get workflow by ID
curl -X GET "http://localhost:3004/workflows/WORKFLOW_ID"

# Process next workflow step
curl -X POST "http://localhost:3004/workflows/WORKFLOW_ID/process"

# Complete workflow step
curl -X PUT "http://localhost:3004/workflows/WORKFLOW_ID/step/0/complete" \
  -H "Content-Type: application/json" \
  -d '{
    "result": "Step completed successfully"
  }'

# Get workflow statistics
curl -X GET "http://localhost:3004/workflows/stats"

# Legacy workflow endpoint
curl -X GET "http://localhost:3004/workflow"
```

## Testing Flow Example

Here's a complete testing flow to validate the service:

```bash
# 1. Check health
curl -X GET "http://localhost:3004/health"

# 2. Create test type
curl -X POST "http://localhost:3004/testtypes" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "cbc001",
    "name": "Complete Blood Count",
    "description": "Standard CBC test",
    "category": "Hematology",
    "createdAt": "2025-08-17T10:00:00Z",
    "updatedAt": "2025-08-17T10:00:00Z"
  }'

# 3. Create sample
curl -X POST "http://localhost:3004/samples" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "patient123",
    "testTypeId": "cbc001",
    "collectionDate": "2025-08-17T09:30:00Z",
    "priority": "normal"
  }'

# 4. Get all samples to see the created sample
curl -X GET "http://localhost:3004/samples"

# 5. Create template
curl -X POST "http://localhost:3004/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CBC Report Template",
    "description": "Template for CBC reports",
    "sections": [],
    "category": "hematology"
  }'

# 6. Get service stats
curl -X GET "http://localhost:3004/samples/stats"
curl -X GET "http://localhost:3004/results/stats"
curl -X GET "http://localhost:3004/templates/stats"
curl -X GET "http://localhost:3004/workflows/stats"
```

## Notes

- Replace `SAMPLE_ID`, `RESULT_ID`, `REPORT_ID`, `TEMPLATE_ID`, and `WORKFLOW_ID` with actual IDs from creation responses
- All endpoints support CORS for web client testing
- The service runs on port 3004 by default
- Use proper JSON formatting in request bodies
- Check response status codes and error messages for debugging

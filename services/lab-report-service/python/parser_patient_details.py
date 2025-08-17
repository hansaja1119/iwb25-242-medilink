class PatientDetailsParser:
    def __init__(self, document_text):
        self.document_text = document_text

    def parse(self):
        # Logic to parse patient details from the document_text
        patient_details = {}
        
        # Example parsing logic (to be replaced with actual implementation)
        lines = self.document_text.splitlines()
        for line in lines:
            if "Name:" in line:
                patient_details["name"] = line.split("Name:")[1].strip()
            elif "Age:" in line:
                patient_details["age"] = line.split("Age:")[1].strip()
            elif "Gender:" in line:
                patient_details["gender"] = line.split("Gender:")[1].strip()
            # Add more fields as necessary

        return patient_details
class PrescriptionParser:
    def __init__(self, document_text):
        self.document_text = document_text

    def parse(self):
        # Logic to parse prescription details from the document_text
        # This is a placeholder for the actual parsing logic
        parsed_data = {}
        
        # Example parsing logic (to be replaced with actual implementation)
        lines = self.document_text.splitlines()
        for line in lines:
            if "Medication" in line:
                parsed_data["medication"] = line.split(":")[-1].strip()
            elif "Dosage" in line:
                parsed_data["dosage"] = line.split(":")[-1].strip()
            elif "Frequency" in line:
                parsed_data["frequency"] = line.split(":")[-1].strip()
        
        return parsed_data
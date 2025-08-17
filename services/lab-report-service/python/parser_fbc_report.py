import re
import sys
from base_parser import BaseParser

class FBCReportParser(BaseParser):
    def __init__(self, text, test_type_config=None):
        super().__init__(text, test_type_config)
    
    def _extract_test_specific_data(self):
        """
        Extract FBC-specific blood parameters.
        """
        # Use configured report fields if available, otherwise use defaults
        report_fields = self.test_type_config.get('report_fields', [])
        reference_ranges = self.test_type_config.get('reference_ranges', {})
        
        if report_fields:
            # Use configured fields from database
            self._extract_configured_fields(report_fields, reference_ranges)
        else:
            # Fallback to hardcoded FBC parameters
            self._extract_default_fbc_parameters()
        
        # Try tabular extraction if we didn't find much data
        if len([k for k in self.report_data.keys() if k not in ['Patient', 'Date', 'Doctor', 'Laboratory']]) < 5:
            self._extract_tabular_fbc_data()
    
    def _extract_configured_fields(self, report_fields, reference_ranges):
        """
        Extract fields based on database configuration.
        """
        for field_config in report_fields:
            field_name = field_config['name']
            field_type = field_config.get('type', 'text')
            unit = field_config.get('unit', '')
            
            # Generate patterns for this field
            patterns = self._generate_field_patterns(field_name, unit)
            
            # Extract the field value
            value = self._extract_numeric_value(self.text, patterns, unit)
            
            if value:
                self.report_data[field_name] = value
                print(f" Found configured field {field_name}: {value}", file=sys.stderr)
            else:
                print(f" Not found configured field {field_name}", file=sys.stderr)
    
    def _generate_field_patterns(self, field_name, unit=''):
        """
        Generate regex patterns for a field name.
        """
        base_patterns = [
            rf'{re.escape(field_name)}[:.\s]*([\d\.]+\s*{re.escape(unit)}?)',
            rf'{re.escape(field_name)}\s*([\d\.]+)',
        ]
        
        # Add common abbreviations and variations
        field_variations = {
            'Red Blood Cell Count': ['RBC'],
            'White Blood Cell Count': ['WBC'],
            'Hemoglobin': ['Hb'],
            'Hematocrit': ['Hct'],
            'Mean Cell Volume': ['MCV'],
            'Mean Cell Hemoglobin': ['MCH'],
            'Mean Cell Hemoglobin Concentration': ['MCHC'],
            'Mean Platelet Volume': ['MPV'],
            'Erythrocyte Sedimentation Rate': ['ESR'],
        }
        
        if field_name in field_variations:
            for variation in field_variations[field_name]:
                base_patterns.extend([
                    rf'{variation}[:.\s]*([\d\.]+\s*{re.escape(unit)}?)',
                    rf'{variation}\s*([\d\.]+)',
                ])
        
        return base_patterns
    
    def _extract_default_fbc_parameters(self):
        """
        Fallback method using hardcoded FBC parameters.
        """
        blood_params = {
            'RBC': {
                'patterns': [
                    r'RBC[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?\d+[/\s]*L)',
                    r'Red\s*Blood\s*Cell\s*Count\s*\(RBC\)[:.\s]*([\d\.]+)',
                    r'RBC\s*([\d\.]+)',
                ],
                'unit': 'x 10^12/L'
            },
            'Hemoglobin': {
                'patterns': [
                    r'Hemoglobin[:.\s]*([\d\.]+\s*g[/\s]*dL)',
                    r'Hb[:.\s]*([\d\.]+\s*g[/\s]*dL)',
                    r'Hemoglobin\s*\(Hb\)[:.\s]*([\d\.]+)',
                ],
                'unit': 'g/dL'
            },
            'Hematocrit': {
                'patterns': [
                    r'Hematocrit[:.\s]*([\d\.]+\s*%)',
                    r'Hct[:.\s]*([\d\.]+\s*%)',
                    r'Hematocrit\s*\(Hct\)[:.\s]*([\d\.]+)',
                ],
                'unit': '%'
            },
            'MCV': {
                'patterns': [
                    r'MCV[:.\s]*([\d\.]+\s*fL)',
                    r'MCV\s*([\d\.]+)',
                    r'Mean\s*Cell\s*Volume\s*\(MCV\)[:.\s]*([\d\.]+)',
                ],
                'unit': 'fL'
            },
            'MCH': {
                'patterns': [
                    r'MCH[:.\s]*([\d\.]+\s*pg)',
                    r'MCH\s*([\d\.]+)',
                    r'Mean\s*Cell\s*Hemoglobin\s*\(MCH\)[:.\s]*([\d\.]+)',
                ],
                'unit': 'pg'
            },
            'MCHC': {
                'patterns': [
                    r'MCHC[:.\s]*([\d\.]+\s*g[/\s]*dL)',
                    r'MCHC\s*([\d\.]+)',
                    r'Mean\s*Cell\s*Hemoglobin\s*Concentration\s*\(MCHC\)[:.\s]*([\d\.]+)',
                ],
                'unit': 'g/dL'
            },
            'WBC': {
                'patterns': [
                    r'WBC[:.\s]*([\d\.]+\s*x?\s*10[^\s]*[/\s]*L)',
                    r'White\s*Blood\s*Cell\s*Count\s*\(WBC\)[:.\s]*([\d\.]+)',
                    r'WBC\s*([\d\.]+)',
                ],
                'unit': 'x 10^9/L'
            },
            'Neutrophils': {
                'patterns': [
                    r'Neutrophils[:.\s]*([\d\.]+\s*%)',
                    r'Neutrophils\s*([\d\.]+)',
                ],
                'unit': '%'
            },
            'Lymphocytes': {
                'patterns': [
                    r'Lymphocytes[:.\s]*([\d\.]+\s*%)',
                    r'Lymphocytes\s*([\d\.]+)',
                ],
                'unit': '%'
            },
            'Monocytes': {
                'patterns': [
                    r'Monocytes[:.\s]*([\d\.]+\s*%)',
                    r'Monocytes\s*([\d\.]+)',
                ],
                'unit': '%'
            },
            'Eosinophils': {
                'patterns': [
                    r'Eosinophils[:.\s]*([\d\.]+\s*%)',
                    r'Eosinophils\s*([\d\.]+)',
                ],
                'unit': '%'
            },
            'Basophils': {
                'patterns': [
                    r'Basophils[:.\s]*([\d\.]+\s*%)',
                    r'Basophils\s*([\d\.]+)',
                ],
                'unit': '%'
            },
            'Platelets': {
                'patterns': [
                    r'Platelets[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?\d+[/\s]*L)',
                    r'Platelet\s*Count[:.\s]*([\d\.]+)',
                    r'Platelets\s*([\d\.]+)',
                ],
                'unit': 'x 10^9/L'
            },
            'MPV': {
                'patterns': [
                    r'MPV[:.\s]*([\d\.]+\s*fL)',
                    r'MPV\s*([\d\.]+)',
                ],
                'unit': 'fL'
            },
            'ESR': {
                'patterns': [
                    r'ESR[:.\s]*([\d\.]+\s*mm[/\s]*hr)',
                    r'ESR\s*([\d\.]+)',
                ],
                'unit': 'mm/hr'
            },
        }
        
        # Extract blood parameters
        for param, config in blood_params.items():
            patterns = config['patterns']
            unit = config['unit']
            
            for pattern in patterns:
                match = re.search(pattern, self.text, re.IGNORECASE)
                if match:
                    value = match.group(1).strip()
                    
                    # Add units if missing
                    if unit not in value and not any(u in value for u in ['x', '10', '%', 'g/dL', 'fL', 'pg', 'mm/hr']):
                        value += f' {unit}'
                    
                    self.report_data[param] = value
                    print(f" Found {param}: {value}", file=sys.stderr)
                    break
                else:
                    print(f" Not found {param} with pattern: {pattern}", file=sys.stderr)
    
    def _extract_tabular_fbc_data(self):
        """
        Extract FBC data from tabular format.
        """
        print("=== TRYING TABULAR EXTRACTION ===", file=sys.stderr)
        
        lines = self.text.split('\n')
        
        # Define markers for tabular data
        start_markers = {
            'Red Blood Cell Count': 'RBC',
            'Hemoglobin': 'Hemoglobin',
            'Hematocrit': 'Hematocrit',
            'MCV': 'MCV',
            'MCH': 'MCH',
            'MCHC': 'MCHC',
            'WBC': 'WBC',
            'Platelets': 'Platelets',
            'MPV': 'MPV',
            'ESR': 'ESR'
        }
        
        # Define value patterns for each parameter
        value_patterns = {
            'RBC': [r'([\d\.]+)'],
            'Hemoglobin': [r'([\d\.]+)'],
            'Hematocrit': [r'([\d\.]+)'],
            'MCV': [r'([\d\.]+)'],
            'MCH': [r'([\d\.]+)'],
            'MCHC': [r'([\d\.]+)'],
            'WBC': [r'([\d\.]+)'],
            'Platelets': [r'([\d\.]+)'],
            'MPV': [r'([\d\.]+)'],
            'ESR': [r'([\d\.]+)']
        }
        
        # Use base parser's tabular extraction method
        tabular_data = self._extract_tabular_data(lines, start_markers, value_patterns)
        
        # Add units to extracted tabular data
        unit_map = {
            'RBC': ' x 10^12/L',
            'Hemoglobin': ' g/dL',
            'Hematocrit': ' %',
            'MCV': ' fL',
            'MCH': ' pg',
            'MCHC': ' g/dL',
            'WBC': ' x 10^9/L',
            'Platelets': ' x 10^9/L',
            'MPV': ' fL',
            'ESR': ' mm/hr'
        }
        
        for param, value in tabular_data.items():
            if param not in self.report_data:  # Don't override existing data
                final_value = value + unit_map.get(param, '')
                self.report_data[param] = final_value
                print(f" Found tabular {param}: {final_value}", file=sys.stderr)
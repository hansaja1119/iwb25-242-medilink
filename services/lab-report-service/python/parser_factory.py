#!/usr/bin/env python3
import importlib
import sys
import json
import re
from base_parser import BaseParser

class DynamicParserFactory:
    """
    Factory class for creating parsers dynamically based on test type configuration.
    """
    
    def __init__(self):
        self.parser_cache = {}
    
    def create_parser(self, text, test_type_config):
        """
        Create a parser instance based on test type configuration.
        
        Args:
            text: The text to parse
            test_type_config: Configuration dictionary containing parser details
            
        Returns:
            Parser instance
        """
        parser_module = test_type_config.get('parser_module')
        parser_class = test_type_config.get('parser_class')
        
        if not parser_module or not parser_class:
            print(f"=== USING GENERIC PARSER ===", file=sys.stderr)
            return GenericParser(text, test_type_config)
        
        try:
            # Try to import the specified parser module
            if parser_module not in self.parser_cache:
                print(f"=== IMPORTING PARSER MODULE: {parser_module} ===", file=sys.stderr)
                module = importlib.import_module(parser_module)
                self.parser_cache[parser_module] = module
            else:
                module = self.parser_cache[parser_module]
            
            # Get the parser class from the module
            parser_cls = getattr(module, parser_class)
            
            print(f"=== CREATING PARSER: {parser_class} ===", file=sys.stderr)
            return parser_cls(text, test_type_config)
            
        except (ImportError, AttributeError) as e:
            print(f"=== PARSER IMPORT ERROR: {str(e)} ===", file=sys.stderr)
            print(f"=== FALLING BACK TO GENERIC PARSER ===", file=sys.stderr)
            return GenericParser(text, test_type_config)
    
    def get_available_parsers(self):
        """
        Get list of available parser modules and classes.
        """
        available_parsers = [
            {
                'module': 'parser_fbc_report',
                'class': 'FBCReportParser',
                'name': 'FBC Report Parser',
                'description': 'Full Blood Count report parser'
            },
            {
                'module': 'parser_lab_report',
                'class': 'LabReportParser',
                'name': 'General Lab Report Parser',
                'description': 'General laboratory report parser'
            },
            {
                'module': 'parser_prescription',
                'class': 'PrescriptionParser',
                'name': 'Prescription Parser',
                'description': 'Prescription document parser'
            },
            {
                'module': 'parser_patient_details',
                'class': 'PatientDetailsParser',
                'name': 'Patient Details Parser',
                'description': 'Patient information parser'
            }
        ]
        
        return available_parsers


class GenericParser(BaseParser):
    """
    Generic parser that uses configuration to extract fields dynamically.
    This is used when no specific parser is available for a test type.
    """
    
    def _extract_test_specific_data(self):
        """
        Extract test-specific data using configuration from database.
        """
        report_fields = self.test_type_config.get('report_fields', [])
        
        print(f"=== GENERIC PARSER: Processing {len(report_fields)} configured fields ===", file=sys.stderr)
        
        # If no fields are configured, try intelligent content detection
        if len(report_fields) == 0:
            print("=== GENERIC PARSER: No configured fields, attempting content detection ===", file=sys.stderr)
            self._detect_and_extract_content()
            return
        
        for field_config in report_fields:
            field_name = field_config['name']
            field_type = field_config.get('type', 'text')
            unit = field_config.get('unit', '')
            required = field_config.get('required', False)
            
            print(f" Processing field: {field_name} (type: {field_type}, unit: {unit})", file=sys.stderr)
            
            if field_type in ['number', 'decimal']:
                # For numeric fields, try to extract with units
                patterns = self._generate_numeric_patterns(field_name, unit)
                value = self._extract_numeric_value(self.text, patterns, unit)
            else:
                # For text fields, try to extract text
                patterns = self._generate_text_patterns(field_name)
                value = self._extract_text_value(patterns)
            
            if value:
                self.report_data[field_name] = value
                print(f" Found {field_name}: {value}", file=sys.stderr)
            elif required:
                print(f" Warning: Required field '{field_name}' not found", file=sys.stderr)
    
    def _detect_and_extract_content(self):
        """
        Detect content type and extract accordingly when no fields are configured.
        """
        text_lower = self.text.lower()
        
        # Check for thyroid function content
        if any(keyword in text_lower for keyword in ['thyroid function', 'tsh', 'free t4', 'free t3', 'endocrine']):
            print("=== DETECTED THYROID CONTENT: Using thyroid extraction patterns ===", file=sys.stderr)
            self._extract_thyroid_patterns()
        # Check for FBC/CBC content
        elif any(keyword in text_lower for keyword in ['full blood count', 'complete blood count', 'fbc', 'cbc', 'hemoglobin', 'hematocrit']):
            print("=== DETECTED FBC CONTENT: Using FBC extraction patterns ===", file=sys.stderr)
            self._extract_fbc_patterns()
        elif any(keyword in text_lower for keyword in ['cholesterol', 'glucose', 'creatinine', 'urea']):
            print("=== DETECTED LAB CONTENT: Using general lab patterns ===", file=sys.stderr)
            self._extract_lab_patterns()
        else:
            print("=== GENERIC CONTENT: Using enhanced table extraction ===", file=sys.stderr)
            self._extract_enhanced_table_data()
    
    def _extract_thyroid_patterns(self):
        """
        Extract thyroid function test values using standard patterns.
        """
        thyroid_patterns = {
            'TSH': [
                r'TSH[:\|\s]*([\d\.\-\+]+)\s*mIU/L',
                r'Thyroid\s*Stimulating\s*Hormone[:\|\s]*([\d\.\-\+]+)',
                r'\|\s*TSH\s*\|\s*([\d\.\-\+]+)\s*\|',
                r'TSH.*?([\d\.\-\+]+)',
            ],
            'Free T4': [
                r'Free\s*T4[:\|\s]*([\d\.\-\+]+)\s*ng/dL',
                r'Free\s*Thyroxine[:\|\s]*([\d\.\-\+]+)',
                r'\|\s*Free\s*T4\s*\|\s*([\d\.\-\+]+)\s*\|',
                r'Free\s*T4.*?([\d\.\-\+]+)',
            ],
            'Free T3': [
                r'Free\s*T3[:\|\s]*([\d\.\-\+]+)\s*pg/mL',
                r'Free\s*Triiodothyronine[:\|\s]*([\d\.\-\+]+)',
                r'\|\s*Free\s*T3\s*\|\s*([\d\.\-\+]+)\s*\|',
                r'Free\s*T3.*?([\d\.\-\+]+)',
            ],
            'T4:T3 Ratio': [
                r'T4[:T]*\s*T3\s*Ratio[:\|\s]*([\d\.\-\+]+)',
                r'T4/T3[:\|\s]*([\d\.\-\+]+)',
                r'\|\s*T4:T3\s*Ratio\s*\|\s*([\d\.\-\+]+)\s*\|',
            ],
            'Free T4 Index': [
                r'Free\s*T4\s*Index[:\|\s]*([\d\.\-\+]+)',
                r'FTI[:\|\s]*([\d\.\-\+]+)',
                r'\|\s*Free\s*T4\s*Index\s*\|\s*([\d\.\-\+]+)\s*\|',
            ]
        }
        
        for field_name, patterns in thyroid_patterns.items():
            value = self._extract_numeric_value(self.text, patterns)
            if value:
                self.report_data[field_name] = value
                print(f" Found thyroid field {field_name}: {value}", file=sys.stderr)
    
    def _extract_fbc_patterns(self):
        """
        Extract FBC values using standard patterns.
        """
        fbc_patterns = {
            'RBC': [r'RBC[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?12[/L]*)', r'Red\s*Blood\s*Cells?[:.\s]*([\d\.]+)'],
            'Hemoglobin': [r'H[ae]moglobin[:.\s]*([\d\.]+\s*g/dL)', r'Hb[:.\s]*([\d\.]+)'],
            'Hematocrit': [r'H[ae]matocrit[:.\s]*([\d\.]+\s*%)', r'Hct[:.\s]*([\d\.]+)'],
            'WBC': [r'WBC[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?9[/L]*)', r'White\s*Blood\s*Cells?[:.\s]*([\d\.]+)'],
            'Platelets': [r'Platelets?[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?9[/L]*)', r'PLT[:.\s]*([\d\.]+)'],
            'MCV': [r'MCV[:.\s]*([\d\.]+\s*fL)', r'Mean\s*Cell\s*Volume[:.\s]*([\d\.]+)'],
            'MCH': [r'MCH[:.\s]*([\d\.]+\s*pg)', r'Mean\s*Cell\s*Hemoglobin[:.\s]*([\d\.]+)'],
            'MCHC': [r'MCHC[:.\s]*([\d\.]+\s*g/dL)', r'Mean\s*Cell\s*Hemoglobin\s*Concentration[:.\s]*([\d\.]+)']
        }
        
        for field_name, patterns in fbc_patterns.items():
            value = self._extract_numeric_value(self.text, patterns)
            if value:
                self.report_data[field_name] = value
                print(f" Found FBC field {field_name}: {value}", file=sys.stderr)
    
    def _extract_lab_patterns(self):
        """
        Extract general lab values using standard patterns.
        """
        lab_patterns = {
            'Glucose': [r'Glucose[:.\s]*([\d\.]+\s*mg/dL)', r'Blood\s*Sugar[:.\s]*([\d\.]+)'],
            'Cholesterol': [r'Cholesterol[:.\s]*([\d\.]+\s*mg/dL)', r'Total\s*Cholesterol[:.\s]*([\d\.]+)'],
            'Creatinine': [r'Creatinine[:.\s]*([\d\.]+\s*mg/dL)', r'Creat[:.\s]*([\d\.]+)'],
            'BUN': [r'BUN[:.\s]*([\d\.]+\s*mg/dL)', r'Blood\s*Urea\s*Nitrogen[:.\s]*([\d\.]+)']
        }
        
        for field_name, patterns in lab_patterns.items():
            value = self._extract_numeric_value(self.text, patterns)
            if value:
                self.report_data[field_name] = value
                print(f" Found lab field {field_name}: {value}", file=sys.stderr)
    
    def _extract_enhanced_table_data(self):
        """
        Enhanced table extraction using the base parser's table methods.
        """
        # Use the enhanced table extraction from base parser
        table_data = self._extract_table_rows(self.text)
        for field_name, value in table_data.items():
            self.report_data[field_name] = value
        
        # If still no data, try the basic patterns as final fallback
        if not table_data:
            self._extract_basic_patterns()
    
    def _extract_basic_patterns(self):
        """
        Extract any numeric values with units as a fallback.
        """
        # Improved basic pattern to avoid fragmented matches
        # Look for complete parameter-value pairs
        basic_patterns = [
            # Pattern 1: Parameter: Value Unit (more restrictive)
            r'([A-Za-z][A-Za-z\s]{2,25})[:\.]\s*([\d\.\-\+]+(?:\s*x?\s*10[\*\^]?[\d\-\+]*)?)\s*([A-Za-z/%\^\*\s]{0,15})',
            # Pattern 2: Parameter (Abbrev): Value
            r'([A-Za-z\s]+)\s*\([A-Za-z0-9]+\)[:\.]\s*([\d\.\-\+]+)',
            # Pattern 3: Single word parameter: value
            r'([A-Z][A-Za-z]{2,15})[:\.]\s*([\d\.\-\+]+)',
        ]
        
        for pattern in basic_patterns:
            matches = re.finditer(pattern, self.text, re.IGNORECASE)
            for match in matches:
                groups = match.groups()
                if len(groups) >= 2:
                    field_name = groups[0].strip()
                    value = groups[1].strip()
                    unit = groups[2].strip() if len(groups) > 2 else ''
                    
                    # Clean field name and apply filters
                    field_name = re.sub(r'[^\w\s\(\)]', '', field_name).strip()
                    
                    # Skip if field name is too short, too long, or generic
                    if (len(field_name) < 3 or len(field_name) > 30 or 
                        field_name.lower() in ['test', 'result', 'reference', 'units', 'status', 'normal', 'report', 'date', 'page']):
                        continue
                    
                    # Skip if field name is already found
                    if field_name in self.report_data:
                        continue
                        
                    # Combine value with unit if available
                    if unit and unit not in value and len(unit) < 10:
                        full_value = f"{value} {unit}"
                    else:
                        full_value = value
                        
                    self.report_data[field_name] = full_value
                    print(f" Found basic field {field_name}: {full_value}", file=sys.stderr)
    
    def _generate_numeric_patterns(self, field_name, unit=''):
        """
        Generate regex patterns for numeric fields.
        """
        escaped_name = field_name.replace(' ', r'\s*')
        escaped_unit = unit.replace('/', r'[/\s]*') if unit else ''
        
        patterns = [
            rf'{escaped_name}[:.\s]*([\d\.]+\s*{escaped_unit})',
            rf'{escaped_name}\s*([\d\.]+)',
            rf'{escaped_name}[:.\s]*([\d\.]+\s*x?\s*10[\*\^]?\d+\s*{escaped_unit})',  # Scientific notation
        ]
        
        return patterns
    
    def _generate_text_patterns(self, field_name):
        """
        Generate regex patterns for text fields.
        """
        escaped_name = field_name.replace(' ', r'\s*')
        
        patterns = [
            rf'{escaped_name}[:.\s]*([^\n\r]+)',
            rf'{escaped_name}\s*[:.]?\s*([A-Za-z\s]+)',
        ]
        
        return patterns
    
    def _extract_text_value(self, patterns):
        """
        Extract text value using the given patterns.
        """
        for pattern in patterns:
            match = re.search(pattern, self.text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None


# Factory instance for global use
parser_factory = DynamicParserFactory()

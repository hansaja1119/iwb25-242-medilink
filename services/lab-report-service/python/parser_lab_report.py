import re
from base_parser import BaseParser

class LabReportParser(BaseParser):
    def __init__(self, text, test_type_config=None):
        super().__init__(text, test_type_config)
    
    def _extract_test_specific_data(self):
        """
        Extract general lab report data including vital signs and blood tests.
        """
        import sys
        
        # Use configured report fields if available, otherwise use defaults
        report_fields = self.test_type_config.get('report_fields', [])
        
        if report_fields:
            print(f" Using {len(report_fields)} configured fields", file=sys.stderr)
            # Use configured fields from database with enhanced table extraction
            self._extract_configured_fields_enhanced(report_fields)
        else:
            # Fallback to hardcoded lab parameters
            print(" No configured fields, using default extraction", file=sys.stderr)
            self._extract_default_lab_parameters()
        
        # Always try table extraction as a fallback
        if len([k for k in self.report_data.keys() if k not in ['Patient', 'Date', 'Doctor', 'Laboratory']]) < len(report_fields) / 2:
            print(" Insufficient fields found, trying enhanced table extraction", file=sys.stderr)
            self._extract_table_data_enhanced()
    
    def _extract_configured_fields_enhanced(self, report_fields):
        """
        Extract fields based on database configuration with enhanced table support.
        """
        import sys
        
        # First try structured table extraction
        table_data = self._extract_structured_table(self.text, report_fields)
        for field_name, value in table_data.items():
            self.report_data[field_name] = value
        
        # Then try individual field patterns for any missing fields
        for field_config in report_fields:
            field_name = field_config['name']
            unit = field_config.get('unit', '')
            
            # Skip if already found in table extraction
            if field_name in self.report_data:
                continue
            
            # Generate patterns for this field
            patterns = self._generate_lab_field_patterns_enhanced(field_name, unit)
            
            # Extract the field value
            value = self._extract_numeric_value(self.text, patterns, unit)
            
            if value:
                self.report_data[field_name] = value
                print(f" Found configured field {field_name}: {value}", file=sys.stderr)
    
    def _extract_table_data_enhanced(self):
        """
        Enhanced table extraction for lab reports.
        """
        import sys
        
        # Try general table extraction
        table_data = self._extract_table_rows(self.text)
        for field_name, value in table_data.items():
            if field_name not in self.report_data:
                self.report_data[field_name] = value
        
        # Specific patterns for common lab values in tables - ENHANCED TO AVOID REFERENCE RANGES
        thyroid_patterns = {
            'TSH': [
                # PRIORITY: Result before reference range - "TSH 2.1 0.4-4.0" -> captures "2.1"
                r'(?:TSH|Thyroid\s*Stimulating\s*Hormone)[^0-9]*?([\d\.\-\+]+)(?:\s+[\d\.\-\+]+\s*-\s*[\d\.\-\+]+)',
                # Single value patterns (exclude ranges with negative lookbehind for dash)
                r'TSH[:\|\s]*([\d\.\-\+]+)(?!\s*-)\s*(?:mIU/L|μIU/mL|uIU/mL)?',
                r'Thyroid\s*Stimulating\s*Hormone[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'\|\s*TSH\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                # Multi-line patterns for table format (result on next line)
                r'(?:TSH|Thyroid\s*Stimulating\s*Hormone)[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                # Last resort: any TSH value not followed by dash
                r'TSH.*?([\d\.\-\+]+)(?!\s*-)',
            ],
            'Free T4': [
                # PRIORITY: Result before reference range - "Free T4 1.3 0.8-1.8" -> captures "1.3"
                r'(?:Free\s*T4|Free\s*Thyroxine)[^0-9]*?([\d\.\-\+]+)(?:\s+[\d\.\-\+]+\s*-\s*[\d\.\-\+]+)',
                # Single value patterns
                r'Free\s*T4[:\|\s]*([\d\.\-\+]+)(?!\s*-)\s*(?:ng/dL|pmol/L|ng/dl)?',
                r'Free\s*Thyroxine[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'\|\s*Free\s*T4\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                # Multi-line patterns
                r'(?:Free\s*T4|Free\s*Thyroxine)[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                # Last resort
                r'Free\s*T4.*?([\d\.\-\+]+)(?!\s*-)',
            ],
            'Free T3': [
                # PRIORITY: Result before reference range - "Free T3 3.2 2.3-4.2" -> captures "3.2"  
                r'(?:Free\s*T3|Free\s*Triiodothyronine)[^0-9]*?([\d\.\-\+]+)(?:\s+[\d\.\-\+]+\s*-\s*[\d\.\-\+]+)',
                # Single value patterns
                r'Free\s*T3[:\|\s]*([\d\.\-\+]+)(?!\s*-)\s*(?:pg/mL|pmol/L)?',
                r'Free\s*Triiodothyronine[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'\|\s*Free\s*T3\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                # Multi-line patterns
                r'(?:Free\s*T3|Free\s*Triiodothyronine)[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                # Last resort
                r'Free\s*T3.*?([\d\.\-\+]+)(?!\s*-)',
            ],
            'T4:T3 Ratio': [
                # Ratio is typically a single value, should be fine as-is
                r'T4[:T]*\s*T3\s*Ratio[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'T4/T3[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'\|\s*T4:T3\s*Ratio\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                # Multi-line patterns
                r'T4[:T]*\s*T3\s*Ratio[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                r'T4[:T]*\s*T3\s*Ratio.*?([\d\.\-\+]+)(?!\s*-)',
            ],
            'Free T4 Index': [
                # Index should be a single value like 6.8, not reference range
                r'Free\s*T4\s*Index[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'FTI[:\|\s]*([\d\.\-\+]+)(?!\s*-)',
                r'\|\s*Free\s*T4\s*Index\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                # Multi-line patterns
                r'Free\s*T4\s*Index[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                r'Free\s*T4\s*Index.*?([\d\.\-\+]+)(?!\s*-)',
            ]
        }
        
        for field_name, patterns in thyroid_patterns.items():
            if field_name not in self.report_data:
                value = self._extract_numeric_value(self.text, patterns)
                if value:
                    self.report_data[field_name] = value
                    print(f" Found table field {field_name}: {value}", file=sys.stderr)
    
    def _generate_lab_field_patterns_enhanced(self, field_name, unit=''):
        """
        Generate enhanced regex patterns for lab field names including table formats.
        """
        escaped_name = re.escape(field_name).replace(r'\ ', r'\s*')
        escaped_unit = re.escape(unit) if unit else ''
        
        patterns = [
            # Table format with pipes
            rf'\|\s*{escaped_name}\s*\|\s*([\d\.\-\+]+)\s*\|',
            # Standard colon format
            rf'{escaped_name}[:\s]*([\d\.\-\+]+\s*{escaped_unit})',
            rf'{escaped_name}[:\s]*([\d\.\-\+]+)',
            # Parentheses format for abbreviations
            rf'{escaped_name}\s*\([^)]*\)[:\s]*([\d\.\-\+]+)',
            # Space-separated table format
            rf'{escaped_name}\s+([\d\.\-\+]+)\s*{escaped_unit}',
            # Scientific notation
            rf'{escaped_name}[:\s]*([\d\.\-\+]+\s*x?\s*10[\*\^]?[\d\-\+]*)',
        ]
        
        # Add specific patterns for common field names
        field_lower = field_name.lower()
        if 'tsh' in field_lower:
            patterns.extend([
                r'TSH[:\|\s]*([\d\.\-\+]+)',
                r'Thyroid\s*Stimulating\s*Hormone[:\|\s]*([\d\.\-\+]+)',
            ])
        elif 'free t4' in field_lower or 't4' in field_lower:
            patterns.extend([
                r'Free\s*T4[:\|\s]*([\d\.\-\+]+)',
                r'Free\s*Thyroxine[:\|\s]*([\d\.\-\+]+)',
            ])
        elif 'free t3' in field_lower or 't3' in field_lower:
            patterns.extend([
                r'Free\s*T3[:\|\s]*([\d\.\-\+]+)',
                r'Free\s*Triiodothyronine[:\|\s]*([\d\.\-\+]+)',
            ])
        
        return patterns
        
        # Add common variations
        field_variations = {
            'Blood Pressure': [r'Blood\s*Pressure[:\s]*(\d+[/\\]\d+)'],
            'Heart Rate': [r'Heart\s*Rate[:\s]*(\d+)'],
            'Temperature': [r'Temperature[:\s]*(\d+\.?\d*)'],
            'Cholesterol': [r'Cholesterol[:\s]*(\d+\.?\d*\s*mg/dL)'],
            'Glucose': [r'Glucose[:\s]*(\d+\.?\d*\s*mg/dL)'],
            'Hemoglobin': [r'Hemoglobin[:\s]*(\d+\.?\d*\s*g/dL)'],
        }
        
        if field_name in field_variations:
            patterns.extend(field_variations[field_name])
        
        return patterns
    
    def _extract_default_lab_parameters(self):
        """
        Extract default lab parameters when no configuration is available.
        """
        # Vital Signs
        bp_match = re.search(r'Blood\s*Pressure[:\s]*(\d+[/\\]\d+)', self.text, re.IGNORECASE)
        if bp_match:
            self.report_data['Blood_Pressure'] = bp_match.group(1).strip()
        
        heart_rate_match = re.search(r'Heart\s*Rate[:\s]*(\d+)', self.text, re.IGNORECASE)
        if heart_rate_match:
            self.report_data['Heart_Rate'] = heart_rate_match.group(1).strip()
        
        temperature_match = re.search(r'Temperature[:\s]*(\d+\.?\d*)', self.text, re.IGNORECASE)
        if temperature_match:
            self.report_data['Temperature'] = temperature_match.group(1).strip()
        
        # Blood Tests
        cholesterol_match = re.search(r'Cholesterol[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if cholesterol_match:
            self.report_data['Cholesterol'] = cholesterol_match.group(1).strip()
        
        glucose_match = re.search(r'Glucose[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if glucose_match:
            self.report_data['Glucose'] = glucose_match.group(1).strip()
        
        hemoglobin_match = re.search(r'Hemoglobin[:\s]*(\d+\.?\d*\s*g/dL)', self.text, re.IGNORECASE)
        if hemoglobin_match:
            self.report_data['Hemoglobin'] = hemoglobin_match.group(1).strip()
        
        # Additional common lab values
        sodium_match = re.search(r'Sodium[:\s]*(\d+\.?\d*\s*mEq/L)', self.text, re.IGNORECASE)
        if sodium_match:
            self.report_data['Sodium'] = sodium_match.group(1).strip()
        
        potassium_match = re.search(r'Potassium[:\s]*(\d+\.?\d*\s*mEq/L)', self.text, re.IGNORECASE)
        if potassium_match:
            self.report_data['Potassium'] = potassium_match.group(1).strip()
        
        creatinine_match = re.search(r'Creatinine[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if creatinine_match:
            self.report_data['Creatinine'] = creatinine_match.group(1).strip()
        
        bun_match = re.search(r'BUN[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if bun_match:
            self.report_data['BUN'] = bun_match.group(1).strip()
        
        # Liver function tests
        alt_match = re.search(r'ALT[:\s]*(\d+\.?\d*\s*U/L)', self.text, re.IGNORECASE)
        if alt_match:
            self.report_data['ALT'] = alt_match.group(1).strip()
        
        ast_match = re.search(r'AST[:\s]*(\d+\.?\d*\s*U/L)', self.text, re.IGNORECASE)
        if ast_match:
            self.report_data['AST'] = ast_match.group(1).strip()
        
        # Thyroid function
        tsh_match = re.search(r'TSH[:\s]*(\d+\.?\d*\s*mIU/L)', self.text, re.IGNORECASE)
        if tsh_match:
            self.report_data['TSH'] = tsh_match.group(1).strip()
        
        # Lipid panel
        ldl_match = re.search(r'LDL[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if ldl_match:
            self.report_data['LDL'] = ldl_match.group(1).strip()
        
        hdl_match = re.search(r'HDL[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if hdl_match:
            self.report_data['HDL'] = hdl_match.group(1).strip()
        
        triglycerides_match = re.search(r'Triglycerides[:\s]*(\d+\.?\d*\s*mg/dL)', self.text, re.IGNORECASE)
        if triglycerides_match:
            self.report_data['Triglycerides'] = triglycerides_match.group(1).strip()
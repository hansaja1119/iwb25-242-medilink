#!/usr/bin/env python3
import re
import sys
import json
from abc import ABC, abstractmethod

class BaseParser(ABC):
    """
    Base class for all report parsers.
    Provides common functionality for extracting basic information
    and handling test-specific parsing.
    """
    
    def __init__(self, text, test_type_config=None):
        self.text = text
        self.test_type_config = test_type_config or {}
        self.report_data = {}
    
    def parse(self):
        """
        Main parsing method that orchestrates the extraction process.
        """
        print(f"=== {self.__class__.__name__} DEBUG ===", file=sys.stderr)
        print(f"Input text length: {len(self.text)}", file=sys.stderr)
        print("Raw text:", repr(self.text[:500]), file=sys.stderr)
        
        # Extract basic information required for all reports
        self._extract_basic_information()
        
        # Extract test-specific information
        self._extract_test_specific_data()
        
        # Validate results
        self._validate_results()
        
        print(f"=== TOTAL EXTRACTED FIELDS: {len(self.report_data)} ===", file=sys.stderr)
        return self.report_data
    
    def _extract_basic_information(self):
        """
        Extract basic information common to all lab reports.
        Uses configuration from test type if available.
        """
        basic_fields = self.test_type_config.get('basic_fields', self._get_default_basic_fields())
        
        for field_config in basic_fields:
            field_name = field_config['name']
            patterns = field_config['patterns']
            required = field_config.get('required', False)
            
            found = False
            for pattern in patterns:
                match = re.search(pattern, self.text, re.IGNORECASE)
                if match:
                    # Some legacy patterns (e.g. 'CENTRAL\s*MEDICAL\s*LABORATORY') have no capturing group.
                    # Use first capturing group if present; otherwise the whole match to avoid IndexError.
                    try:
                        if match.lastindex and match.lastindex >= 1:
                            value = match.group(1).strip()
                        else:
                            value = match.group(0).strip()
                    except IndexError:
                        # Fallback defensively to full match
                        value = match.group(0).strip()
                    
                    # Special handling for laboratory field
                    if field_name == 'Laboratory' and 'CENTRAL' in pattern:
                        value = 'Central Medical Laboratory'
                    
                    self.report_data[field_name] = value
                    print(f" Found {field_name}: {value}", file=sys.stderr)
                    found = True
                    break
            
            if not found and required:
                print(f" Warning: Required field '{field_name}' not found", file=sys.stderr)
    
    def _get_default_basic_fields(self):
        """
        Default basic fields configuration for all reports.
        """
        return [
            {
                'name': 'Patient',
                'required': True,
                'patterns': [
                    r'Patient:\s*(.+)',
                    r'Patient\s*Name:\s*(.+)',
                    r'Name:\s*(.+)',
                ]
            },
            {
                'name': 'Date',
                'required': True,
                'patterns': [
                    r'Date:\s*(.+)',
                    r'Collection\s*Date:\s*(.+)',
                    r'Report\s*Date:\s*(.+)',
                ]
            },
            {
                'name': 'Doctor',
                'required': False,
                'patterns': [
                    r'Doctor:\s*(.+)',
                    r'Ordering\s*Physician:\s*(.+)',
                    r'Physician:\s*(.+)',
                ]
            },
            {
                'name': 'Laboratory',
                'required': True,
                'patterns': [
                    r'Laboratory:\s*(.+)',
                    r'Lab:\s*(.+)',
                    r'CENTRAL\s*MEDICAL\s*LABORATORY',
                ]
            }
        ]
    
    @abstractmethod
    def _extract_test_specific_data(self):
        """
        Extract test-specific data. Must be implemented by subclasses.
        """
        pass
    
    def _validate_results(self):
        """
        Validate extracted results against reference ranges if available.
        """
        reference_ranges = self.test_type_config.get('reference_ranges', {})
        
        for field_name, field_value in self.report_data.items():
            if field_name in reference_ranges:
                range_config = reference_ranges[field_name]
                # Add validation logic here if needed
                print(f" Validated {field_name}: {field_value} (Range: {range_config.get('normalRange', 'N/A')})", file=sys.stderr)
    
    def _extract_numeric_value(self, text, patterns, unit=None):
        """
        Helper method to extract numeric values with optional units.
        """
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                value = match.group(1).strip()
                
                # Add unit if missing and provided
                if unit and unit not in value:
                    value += f' {unit}'
                
                return value
        return None
    
    def _extract_tabular_data(self, lines, start_markers, value_patterns):
        """
        Helper method to extract data from tabular formats.
        """
        extracted_data = {}
        
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            
            for marker, param_name in start_markers.items():
                if marker.lower() in line.lower():
                    # Look for the value in the same line or next few lines
                    for j in range(i, min(i + 3, len(lines))):
                        for pattern in value_patterns.get(param_name, [r'([\d\.]+)']):
                            value_match = re.search(pattern, lines[j])
                            if value_match and (j > i or marker.lower() not in lines[j].lower()):
                                extracted_data[param_name] = value_match.group(1)
                                break
                        if param_name in extracted_data:
                            break
                    break
        
        return extracted_data
    
    def _extract_table_rows(self, text):
        """
        Enhanced table extraction method for structured data.
        Detects and extracts data from table-like structures.
        """
        extracted_data = {}
        lines = text.split('\n')
        
        # Look for table headers and data rows
        table_patterns = [
            # Pattern 1: Parameter | Result | Reference | Units | Status
            r'([A-Za-z\s\(\)]+?)\s*\|\s*([\d\.\-\+]+)\s*\|\s*([\d\.\-\+\s\<\>]+)\s*\|\s*([A-Za-z/%]+)\s*\|\s*([A-Z]+)',
            # Pattern 2: Parameter Result Reference Units Status (space separated)
            r'([A-Za-z\s\(\)]+?)\s+([\d\.\-\+]+)\s+([\d\.\-\+\s\<\>]+)\s+([A-Za-z/%]+)\s+([A-Z]+)',
            # Pattern 3: Simple Parameter: Value Unit pattern
            r'([A-Za-z\s\(\)]+?)[:\.]\s*([\d\.\-\+]+)\s*([A-Za-z/%]*)',
            # Pattern 4: TSH specific patterns for thyroid tests
            r'(TSH|Free\s*T[34]|T[34][:T]*\s*Ratio|T[34]\s*Index)\s*[:\|\s]\s*([\d\.\-\+]+)\s*([A-Za-z/%]*)',
            # Pattern 5: Lab values with units in parentheses  
            r'([A-Za-z\s\(\)]+?)\s+([\d\.\-\+]+)\s*\(([A-Za-z/%]+)\)',
        ]
        
        for line in lines:
            line = line.strip()
            if not line or len(line) < 5:
                continue
                
            for pattern in table_patterns:
                matches = re.finditer(pattern, line, re.IGNORECASE)
                for match in matches:
                    groups = match.groups()
                    if len(groups) >= 2:
                        param_name = groups[0].strip()
                        value = groups[1].strip()
                        unit = groups[2].strip() if len(groups) > 2 else ''
                        
                        # Clean parameter name
                        param_name = re.sub(r'[^\w\s\(\)]', '', param_name).strip()
                        
                        # Skip if parameter name is too short or generic
                        if len(param_name) < 2 or param_name.lower() in ['test', 'result', 'reference', 'units', 'status']:
                            continue
                            
                        # Combine value with unit if available
                        if unit and unit not in value:
                            full_value = f"{value} {unit}"
                        else:
                            full_value = value
                            
                        extracted_data[param_name] = full_value
                        print(f" Found table field {param_name}: {full_value}", file=sys.stderr)
        
        return extracted_data
    
    def _extract_structured_table(self, text, field_configs):
        """
        Extract data from structured tables using field configurations.
        This method specifically looks for configured field names in table format.
        """
        extracted_data = {}
        
        for field_config in field_configs:
            field_name = field_config['name']
            field_type = field_config.get('type', 'text')
            unit = field_config.get('unit', '')
            
            # Generate multiple patterns for this field
            patterns = self._generate_table_patterns(field_name, unit, field_type)
            
            # Try to extract the value
            value = self._extract_numeric_value(text, patterns, unit)
            
            if value:
                extracted_data[field_name] = value
                print(f" Found configured table field {field_name}: {value}", file=sys.stderr)
        
        return extracted_data
    
    def _generate_table_patterns(self, field_name, unit='', field_type='text'):
        """
        Generate table-specific patterns for a field.
        """
        # Escape special characters in field name
        escaped_name = re.escape(field_name).replace(r'\ ', r'\s*')
        escaped_unit = re.escape(unit) if unit else ''
        
        patterns = []
        
        if field_type in ['number', 'decimal']:
            # Numeric patterns for tables - prioritize single values over ranges
            patterns.extend([
                # PRIORITY 1: Single numeric value before reference range
                # Pattern: "TSH 2.1 0.4-4.0" -> captures "2.1" not "0.4-4.0"
                rf'{escaped_name}[^0-9]*?([\d\.\-\+]+)(?:\s+[\d\.\-\+]+\s*-\s*[\d\.\-\+]+)',
                
                # PRIORITY 2: Single value with unit, avoiding ranges  
                rf'{escaped_name}[^0-9]*?([\d\.\-\+]+)\s*{escaped_unit}(?!\s*-)',
                
                # PRIORITY 3: Value in table cells with pipes, excluding ranges
                rf'\|\s*{escaped_name}\s*\|\s*([\d\.\-\+]+)(?!\s*-)\s*\|',
                
                # PRIORITY 4: Colon/space separated single values
                rf'{escaped_name}[:\.]\s*([\d\.\-\+]+)(?!\s*-)\s*{escaped_unit}',
                rf'{escaped_name}\s+([\d\.\-\+]+)(?!\s*-)\s*{escaped_unit}',
                
                # PRIORITY 5: Multi-line table format - result on next line
                rf'{escaped_name}[^\n]*\n[^\d]*?([\d\.\-\+]+)(?!\s*-)',
                
                # PRIORITY 6: Parentheses format: Field Name (TSH): Value
                rf'{escaped_name}\s*\([^)]*\)[:\.]\s*([\d\.\-\+]+)(?!\s*-)',
                
                # PRIORITY 7: Scientific notation (single values only)
                rf'{escaped_name}[^0-9]*?([\d\.\-\+]+\s*x?\s*10[\*\^]?[\d\-\+]+)(?!\s*-)',
                
                # FALLBACK: Any single number after field name (as last resort)
                rf'{escaped_name}[^0-9]*?([\d\.\-\+]+)(?!\s*-)',
            ])
        else:
            # Text patterns
            patterns.extend([
                rf'{escaped_name}[:\.]\s*([^\|\n\r]+)',
                rf'\|\s*{escaped_name}\s*\|\s*([^\|\n\r]+)\s*\|',
            ])
        
        return patterns

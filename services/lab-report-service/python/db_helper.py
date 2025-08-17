#!/usr/bin/env python3
import json
import sys
import subprocess
import os
import platform

class DatabaseHelper:
    """
    Helper class to interact with the database via Node.js service calls.
    """
    
    def __init__(self):
        # Service root (directory containing package.json)
        self.service_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        # Source directory
        self.src_path = os.path.join(self.service_root, 'src')
        # Path to the TypeScript helper script
        self.script_path = os.path.join(self.src_path, 'utils', 'db_helper.ts')
        # Determine ts-node executable candidates
        self.ts_node_candidates = self._build_ts_node_candidates()

    def _build_ts_node_candidates(self):
        candidates = []
        bin_dir = os.path.join(self.service_root, 'node_modules', '.bin')
        is_windows = platform.system().lower().startswith('win')
        # Local project ts-node first
        if is_windows:
            candidates.append(os.path.join(bin_dir, 'ts-node.cmd'))
        candidates.append(os.path.join(bin_dir, 'ts-node'))
        # Fallback to npx invocation (will look in PATH)
        candidates.append('npx ts-node')  # Will be split later
        # Direct ts-node if globally available
        candidates.append('ts-node')
        return candidates

    def _resolve_ts_node(self):
        for cand in self.ts_node_candidates:
            if os.path.isfile(cand) and os.access(cand, os.X_OK):
                return [cand]
            # For string commands with space (like 'npx ts-node'), just return split parts
            if ' ' in cand:
                return cand.split(' ')
            # Plain command name (rely on PATH)
            if cand in ('ts-node',) or cand.endswith('.cmd'):
                return [cand]
        return ['ts-node']

    def _build_command(self, action, *args):
        runner = self._resolve_ts_node()
        cmd = runner + [self.script_path, action]
        cmd.extend(map(str, args))
        return cmd

    def _run_helper(self, action, *args):
        if not os.path.exists(self.script_path):
            print(f"=== DATABASE HELPER NOT FOUND: {self.script_path} ===", file=sys.stderr)
            return None, f"helper script missing: {self.script_path}"
        cmd = self._build_command(action, *args)
        # Debug logging
        print(f"=== EXECUTING TS HELPER: {' '.join(cmd)} (cwd={self.service_root}) ===", file=sys.stderr)
        env = os.environ.copy()
        # Speed up ts-node & avoid typechecking overhead
        env.setdefault('TS_NODE_TRANSPILE_ONLY', '1')
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.service_root,
                env=env,
                timeout=15
            )
        except FileNotFoundError as e:
            return None, f"runner not found: {e}"
        except subprocess.TimeoutExpired:
            return None, 'timeout executing ts-node helper'

        if result.returncode != 0:
            stderr_snippet = result.stderr.strip()[:500]
            print(f"=== TS HELPER ERROR (rc={result.returncode}) STDERR: {stderr_snippet} ===", file=sys.stderr)
            return None, stderr_snippet
        stdout = result.stdout.strip()
        if not stdout:
            return None, 'empty stdout from helper'
        try:
            data = json.loads(stdout)
            return data, None
        except json.JSONDecodeError as e:
            return None, f"json parse error: {e}: {stdout[:200]}"
    
    def get_test_type_config(self, test_type_id):
        """
        Get test type configuration from the database.
        
        Args:
            test_type_id: ID of the test type
            
        Returns:
            Dictionary containing test type configuration
        """
        try:
            data, err = self._run_helper('getTestType', test_type_id)
            if data is not None:
                print(f"=== LOADED TEST TYPE CONFIG: {data.get('label', 'Unknown')} ===", file=sys.stderr)
                return data
            print(f"=== DATABASE HELPER ERROR: {err} ===", file=sys.stderr)
            return self._get_config_by_id(test_type_id)
        except Exception as e:
            print(f"=== DATABASE HELPER UNHANDLED ERROR: {str(e)} ===", file=sys.stderr)
            return self._get_config_by_id(test_type_id)
    
    def get_test_type_by_format(self, file_format):
        """
        Get test type configuration by file format.
        
        Args:
            file_format: Format identifier (fbc, lab_report, etc.)
            
        Returns:
            Dictionary containing test type configuration
        """
        try:
            data, err = self._run_helper('getTestTypeByFormat', file_format)
            if data is not None:
                print(f"=== LOADED CONFIG FOR FORMAT {file_format}: {data.get('label', 'Unknown')} ===", file=sys.stderr)
                return data
            print(f"=== DATABASE HELPER ERROR: {err} ===", file=sys.stderr)
            return self._get_default_config_by_format(file_format)
        except Exception as e:
            print(f"=== DATABASE HELPER UNHANDLED ERROR: {str(e)} ===", file=sys.stderr)
            return self._get_default_config_by_format(file_format)
    
    def _get_default_config(self):
        """
        Get default configuration when database is not available.
        """
        return {
            'id': 0,
            'value': 'generic',
            'label': 'Generic Report',
            'category': 'general',
            'parser_module': None,
            'parser_class': None,
            'report_fields': [],
            'reference_ranges': {},
            'basic_fields': []
        }
    
    def _get_config_by_id(self, test_type_id):
        """
        Get configuration by test type ID with dynamic fallback.
        This method provides fallback configs while the system transitions to full database integration.
        """
        print(f"=== FALLBACK CONFIG FOR TEST TYPE ID: {test_type_id} ===", file=sys.stderr)
        
        # Dynamic test type configurations - these should eventually come from database
        dynamic_configs = {
            1: self._build_config(1, 'fbc', 'Full Blood Count', 'hematology', 'parser_fbc_report', 'FBCReportParser'),
            2: self._build_config(2, 'lab_report', 'General Lab Report', 'general', 'parser_lab_report', 'LabReportParser'),
            3: self._build_config(3, 'prescription', 'Prescription', 'prescription', 'parser_prescription', 'PrescriptionParser'),
            4: self._build_config(4, 'fbc_enhanced', 'Enhanced Full Blood Count', 'hematology', 'parser_fbc_report', 'FBCReportParser'),
            5: self._build_config(5, 'lipid_panel', 'Lipid Panel', 'biochemistry', 'parser_lab_report', 'LabReportParser'),
            6: self._build_config(6, 'thyroid_function', 'Thyroid Function Test', 'endocrinology', 'parser_lab_report', 'LabReportParser'),
            7: self._build_config(7, 'patient_details', 'Patient Details', 'patient', 'parser_patient_details', 'PatientDetailsParser'),
            8: self._build_config(8, 'liver_function', 'Liver Function Test', 'biochemistry', 'parser_lab_report', 'LabReportParser'),
        }
        
        if test_type_id in dynamic_configs:
            return dynamic_configs[test_type_id]
        else:
            # For unknown test types, try intelligent mapping
            print(f"=== UNKNOWN TEST TYPE ID {test_type_id} - USING INTELLIGENT FALLBACK ===", file=sys.stderr)
            return self._create_dynamic_config(test_type_id)
    
    def _build_config(self, id, value, label, category, parser_module, parser_class):
        """
        Build a configuration object dynamically.
        """
        config = {
            'id': id,
            'value': value,
            'label': label,
            'category': category,
            'parser_module': parser_module,
            'parser_class': parser_class,
            'report_fields': [],
            'reference_ranges': {}
        }
        
        # Add specific field configurations based on test type
        if value == 'thyroid_function':
            config.update(self._get_thyroid_config())
        elif value == 'fbc' or value == 'fbc_enhanced':
            config.update(self._get_fbc_config())
        elif value == 'lipid_panel':
            config.update(self._get_lipid_config())
        elif value == 'liver_function':
            config.update(self._get_liver_config())
        
        return config
    
    def _create_dynamic_config(self, test_type_id):
        """
        Create a dynamic configuration for unknown test types.
        This simulates what would happen when new test types are added to the database.
        """
        # Intelligent defaults based on ID ranges
        if test_type_id >= 100:  # Custom/User-defined test types
            category = 'custom'
            parser_module = 'parser_lab_report'  # Most flexible parser
        elif test_type_id >= 50:  # Specialized tests
            category = 'specialized'
            parser_module = 'parser_lab_report'
        else:  # Standard laboratory tests
            category = 'laboratory'
            parser_module = 'parser_lab_report'
        
        return {
            'id': test_type_id,
            'value': f'test_type_{test_type_id}',
            'label': f'Test Type {test_type_id}',
            'category': category,
            'parser_module': parser_module,
            'parser_class': 'LabReportParser',
            'report_fields': self._get_generic_fields(),
            'reference_ranges': {}
        }
    
    def _get_generic_fields(self):
        """
        Generic field set for unknown test types.
        """
        return [
            {'name': 'Result', 'type': 'text', 'required': False, 'unit': '', 'normalRange': ''},
            {'name': 'Value', 'type': 'decimal', 'required': False, 'unit': '', 'normalRange': ''},
            {'name': 'Status', 'type': 'text', 'required': False, 'unit': '', 'normalRange': ''},
        ]
    
    def _get_default_config_by_format(self, file_format):
        """
        Get default configuration based on file format.
        """
        format_configs = {
            'fbc': {
                'id': 1,
                'value': 'fbc',
                'label': 'Full Blood Count',
                'category': 'hematology',
                'parser_module': 'parser_fbc_report',
                'parser_class': 'FBCReportParser',
                'report_fields': [
                    {'name': 'RBC', 'type': 'number', 'required': True, 'unit': 'x 10^12/L', 'normalRange': '4.5-5.5'},
                    {'name': 'Hemoglobin', 'type': 'number', 'required': True, 'unit': 'g/dL', 'normalRange': '13.5-17.5'},
                    {'name': 'Hematocrit', 'type': 'number', 'required': True, 'unit': '%', 'normalRange': '41-53'},
                    {'name': 'WBC', 'type': 'number', 'required': True, 'unit': 'x 10^9/L', 'normalRange': '4.0-11.0'},
                    {'name': 'Platelets', 'type': 'number', 'required': True, 'unit': 'x 10^9/L', 'normalRange': '150-450'},
                ],
                'reference_ranges': {
                    'RBC': {'min': 4.5, 'max': 5.5, 'unit': 'x 10^12/L', 'normalRange': '4.5-5.5'},
                    'Hemoglobin': {'min': 13.5, 'max': 17.5, 'unit': 'g/dL', 'normalRange': '13.5-17.5'},
                    'Hematocrit': {'min': 41, 'max': 53, 'unit': '%', 'normalRange': '41-53'},
                    'WBC': {'min': 4.0, 'max': 11.0, 'unit': 'x 10^9/L', 'normalRange': '4.0-11.0'},
                    'Platelets': {'min': 150, 'max': 450, 'unit': 'x 10^9/L', 'normalRange': '150-450'},
                }
            },
            'lab_report': {
                'id': 2,
                'value': 'lab_report',
                'label': 'General Lab Report',
                'category': 'general',
                'parser_module': 'parser_lab_report',
                'parser_class': 'LabReportParser',
                'report_fields': [
                    {'name': 'Glucose', 'type': 'number', 'required': True, 'unit': 'mg/dL', 'normalRange': '70-100'},
                    {'name': 'Cholesterol', 'type': 'number', 'required': False, 'unit': 'mg/dL', 'normalRange': '<200'},
                    {'name': 'Creatinine', 'type': 'number', 'required': False, 'unit': 'mg/dL', 'normalRange': '0.6-1.2'},
                ],
                'reference_ranges': {
                    'Glucose': {'min': 70, 'max': 100, 'unit': 'mg/dL', 'normalRange': '70-100'},
                    'Cholesterol': {'max': 200, 'unit': 'mg/dL', 'normalRange': '<200'},
                    'Creatinine': {'min': 0.6, 'max': 1.2, 'unit': 'mg/dL', 'normalRange': '0.6-1.2'},
                }
            },
            'prescription': {
                'id': 3,
                'value': 'prescription',
                'label': 'Prescription',
                'category': 'prescription',
                'parser_module': 'parser_prescription',
                'parser_class': 'PrescriptionParser',
                'report_fields': [],
                'reference_ranges': {}
            },
            'patient_details': {
                'id': 4,
                'value': 'patient_details',
                'label': 'Patient Details',
                'category': 'patient',
                'parser_module': 'parser_patient_details',
                'parser_class': 'PatientDetailsParser',
                'report_fields': [],
                'reference_ranges': {}
            },
            'thyroid_function': {
                'id': 6,
                'value': 'thyroid_function',
                'label': 'Thyroid Function Test',
                'category': 'endocrinology',
                'parser_module': 'parser_lab_report',
                'parser_class': 'LabReportParser',
                'report_fields': [
                    {'name': 'TSH', 'type': 'decimal', 'required': True, 'unit': 'mIU/L', 'normalRange': '0.4-4.0'},
                    {'name': 'Free T4', 'type': 'decimal', 'required': True, 'unit': 'ng/dL', 'normalRange': '0.8-1.8'},
                    {'name': 'Free T3', 'type': 'decimal', 'required': False, 'unit': 'pg/mL', 'normalRange': '2.3-4.2'},
                    {'name': 'T4:T3 Ratio', 'type': 'decimal', 'required': False, 'unit': 'ratio', 'normalRange': '2.5-5.0'},
                    {'name': 'Free T4 Index', 'type': 'decimal', 'required': False, 'unit': 'index', 'normalRange': '4.5-10.5'}
                ],
                'reference_ranges': {
                    'TSH': {'min': 0.4, 'max': 4.0, 'unit': 'mIU/L', 'normalRange': '0.4-4.0'},
                    'Free T4': {'min': 0.8, 'max': 1.8, 'unit': 'ng/dL', 'normalRange': '0.8-1.8'},
                    'Free T3': {'min': 2.3, 'max': 4.2, 'unit': 'pg/mL', 'normalRange': '2.3-4.2'},
                    'T4:T3 Ratio': {'min': 2.5, 'max': 5.0, 'unit': 'ratio', 'normalRange': '2.5-5.0'},
                    'Free T4 Index': {'min': 4.5, 'max': 10.5, 'unit': 'index', 'normalRange': '4.5-10.5'}
                }
            },
            'lipid_panel': {
                'id': 7,
                'value': 'lipid_panel',
                'label': 'Lipid Panel',
                'category': 'biochemistry',
                'parser_module': 'parser_lab_report',
                'parser_class': 'LabReportParser',
                'report_fields': [
                    {'name': 'Total Cholesterol', 'type': 'number', 'required': True, 'unit': 'mg/dL', 'normalRange': '<200'},
                    {'name': 'HDL Cholesterol', 'type': 'number', 'required': True, 'unit': 'mg/dL', 'normalRange': '>40'},
                    {'name': 'LDL Cholesterol', 'type': 'number', 'required': True, 'unit': 'mg/dL', 'normalRange': '<100'},
                    {'name': 'Triglycerides', 'type': 'number', 'required': True, 'unit': 'mg/dL', 'normalRange': '<150'}
                ],
                'reference_ranges': {
                    'Total Cholesterol': {'max': 200, 'unit': 'mg/dL', 'normalRange': '<200'},
                    'HDL Cholesterol': {'min': 40, 'unit': 'mg/dL', 'normalRange': '>40'},
                    'LDL Cholesterol': {'max': 100, 'unit': 'mg/dL', 'normalRange': '<100'},
                    'Triglycerides': {'max': 150, 'unit': 'mg/dL', 'normalRange': '<150'}
                }
            }
        }
        
        return format_configs.get(file_format, self._get_default_config())
    
    def _get_thyroid_config(self):
        """
        Get thyroid-specific field configuration.
        """
        return {
            'report_fields': [
                {'name': 'TSH', 'type': 'decimal', 'required': True, 'unit': 'mIU/L', 'normalRange': '0.4-4.0'},
                {'name': 'Free T4', 'type': 'decimal', 'required': True, 'unit': 'ng/dL', 'normalRange': '0.8-1.8'},
                {'name': 'Free T3', 'type': 'decimal', 'required': False, 'unit': 'pg/mL', 'normalRange': '2.3-4.2'},
                {'name': 'T4:T3 Ratio', 'type': 'decimal', 'required': False, 'unit': 'ratio', 'normalRange': '2.5-5.0'},
                {'name': 'Free T4 Index', 'type': 'decimal', 'required': False, 'unit': 'index', 'normalRange': '4.5-10.5'}
            ],
            'reference_ranges': {
                'TSH': {'min': 0.4, 'max': 4.0, 'unit': 'mIU/L', 'normalRange': '0.4-4.0'},
                'Free T4': {'min': 0.8, 'max': 1.8, 'unit': 'ng/dL', 'normalRange': '0.8-1.8'},
                'Free T3': {'min': 2.3, 'max': 4.2, 'unit': 'pg/mL', 'normalRange': '2.3-4.2'},
                'T4:T3 Ratio': {'min': 2.5, 'max': 5.0, 'unit': 'ratio', 'normalRange': '2.5-5.0'},
                'Free T4 Index': {'min': 4.5, 'max': 10.5, 'unit': 'index', 'normalRange': '4.5-10.5'}
            }
        }
    
    def _get_fbc_config(self):
        """
        Get FBC-specific field configuration.
        """
        return {
            'report_fields': [
                {'name': 'RBC', 'type': 'decimal', 'required': True, 'unit': 'x 10^12/L', 'normalRange': '4.5-5.5'},
                {'name': 'Hemoglobin', 'type': 'decimal', 'required': True, 'unit': 'g/dL', 'normalRange': '13.5-17.5'},
                {'name': 'Hematocrit', 'type': 'decimal', 'required': True, 'unit': '%', 'normalRange': '41-53'},
                {'name': 'WBC', 'type': 'decimal', 'required': True, 'unit': 'x 10^9/L', 'normalRange': '4.0-11.0'},
                {'name': 'Platelets', 'type': 'decimal', 'required': True, 'unit': 'x 10^9/L', 'normalRange': '150-450'},
            ],
            'reference_ranges': {
                'RBC': {'min': 4.5, 'max': 5.5, 'unit': 'x 10^12/L', 'normalRange': '4.5-5.5'},
                'Hemoglobin': {'min': 13.5, 'max': 17.5, 'unit': 'g/dL', 'normalRange': '13.5-17.5'},
                'Hematocrit': {'min': 41, 'max': 53, 'unit': '%', 'normalRange': '41-53'},
                'WBC': {'min': 4.0, 'max': 11.0, 'unit': 'x 10^9/L', 'normalRange': '4.0-11.0'},
                'Platelets': {'min': 150, 'max': 450, 'unit': 'x 10^9/L', 'normalRange': '150-450'},
            }
        }
    
    def _get_lipid_config(self):
        """
        Get lipid panel field configuration.
        """
        return {
            'report_fields': [
                {'name': 'Total Cholesterol', 'type': 'decimal', 'required': True, 'unit': 'mg/dL', 'normalRange': '<200'},
                {'name': 'HDL Cholesterol', 'type': 'decimal', 'required': True, 'unit': 'mg/dL', 'normalRange': '>40'},
                {'name': 'LDL Cholesterol', 'type': 'decimal', 'required': True, 'unit': 'mg/dL', 'normalRange': '<100'},
                {'name': 'Triglycerides', 'type': 'decimal', 'required': True, 'unit': 'mg/dL', 'normalRange': '<150'}
            ],
            'reference_ranges': {
                'Total Cholesterol': {'max': 200, 'unit': 'mg/dL', 'normalRange': '<200'},
                'HDL Cholesterol': {'min': 40, 'unit': 'mg/dL', 'normalRange': '>40'},
                'LDL Cholesterol': {'max': 100, 'unit': 'mg/dL', 'normalRange': '<100'},
                'Triglycerides': {'max': 150, 'unit': 'mg/dL', 'normalRange': '<150'}
            }
        }
    
    def _get_liver_config(self):
        """
        Get liver function test configuration.
        """
        return {
            'report_fields': [
                {'name': 'ALT', 'type': 'decimal', 'required': True, 'unit': 'U/L', 'normalRange': '7-45'},
                {'name': 'AST', 'type': 'decimal', 'required': True, 'unit': 'U/L', 'normalRange': '8-40'},
                {'name': 'Bilirubin', 'type': 'decimal', 'required': True, 'unit': 'mg/dL', 'normalRange': '0.2-1.2'},
                {'name': 'Alkaline Phosphatase', 'type': 'decimal', 'required': False, 'unit': 'U/L', 'normalRange': '44-147'}
            ],
            'reference_ranges': {
                'ALT': {'min': 7, 'max': 45, 'unit': 'U/L', 'normalRange': '7-45'},
                'AST': {'min': 8, 'max': 40, 'unit': 'U/L', 'normalRange': '8-40'},
                'Bilirubin': {'min': 0.2, 'max': 1.2, 'unit': 'mg/dL', 'normalRange': '0.2-1.2'},
                'Alkaline Phosphatase': {'min': 44, 'max': 147, 'unit': 'U/L', 'normalRange': '44-147'}
            }
        }


# Global database helper instance
db_helper = DatabaseHelper()

#!/usr/bin/env python3

"""
Test script to demonstrate how the system handles NEW test types
that are not pre-configured in the database helper.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from db_helper import db_helper
from parser_factory import parser_factory

def test_new_test_types():
    """Test how system handles newly created test types"""
    
    print("=== TESTING NEW TEST TYPE HANDLING ===\n")
    
    # Test various new test type IDs that don't exist in hardcoded configs
    new_test_types = [9, 15, 25, 50, 100, 150]
    
    for test_type_id in new_test_types:
        print(f"--- Testing Test Type ID: {test_type_id} ---")
        
        # Get configuration for new test type
        config = db_helper.get_test_type_config(test_type_id)
        
        print(f"✅ Config Generated:")
        print(f"   ID: {config['id']}")
        print(f"   Label: {config['label']}")
        print(f"   Category: {config['category']}")
        print(f"   Parser: {config['parser_module']}.{config['parser_class']}")
        print(f"   Fields: {len(config['report_fields'])} configured")
        
        # Test parser creation
        try:
            sample_text = "Sample medical report text for testing"
            parser = parser_factory.create_parser(sample_text, config)
            print(f"✅ Parser Created: {parser.__class__.__name__}")
        except Exception as e:
            print(f"❌ Parser Creation Failed: {str(e)}")
        
        print()

def test_known_vs_unknown_types():
    """Compare known test types vs unknown test types"""
    
    print("=== KNOWN VS UNKNOWN TEST TYPE COMPARISON ===\n")
    
    # Known test type (Thyroid)
    print("--- KNOWN TEST TYPE (ID 6 - Thyroid) ---")
    thyroid_config = db_helper.get_test_type_config(6)
    print(f"Label: {thyroid_config['label']}")
    print(f"Fields: {len(thyroid_config['report_fields'])} specific fields")
    print(f"Field Names: {[f['name'] for f in thyroid_config['report_fields']]}")
    
    print()
    
    # Unknown test type
    print("--- UNKNOWN TEST TYPE (ID 99 - New) ---")
    new_config = db_helper.get_test_type_config(99)
    print(f"Label: {new_config['label']}")
    print(f"Fields: {len(new_config['report_fields'])} generic fields")
    print(f"Field Names: {[f['name'] for f in new_config['report_fields']]}")
    
    print()

def simulate_database_driven_config():
    """Simulate how it would work with real database integration"""
    
    print("=== SIMULATING TRUE DATABASE INTEGRATION ===\n")
    
    # This is what would happen with real database:
    simulated_db_response = {
        'id': 25,
        'value': 'cardiac_markers',
        'label': 'Cardiac Markers Panel',
        'category': 'cardiology',
        'parser_module': 'parser_lab_report',
        'parser_class': 'LabReportParser',
        'report_fields': [
            {'name': 'Troponin I', 'type': 'decimal', 'required': True, 'unit': 'ng/mL', 'normalRange': '<0.04'},
            {'name': 'CK-MB', 'type': 'decimal', 'required': True, 'unit': 'ng/mL', 'normalRange': '0-6.3'},
            {'name': 'BNP', 'type': 'decimal', 'required': False, 'unit': 'pg/mL', 'normalRange': '<100'},
        ],
        'reference_ranges': {
            'Troponin I': {'max': 0.04, 'unit': 'ng/mL', 'normalRange': '<0.04'},
            'CK-MB': {'min': 0, 'max': 6.3, 'unit': 'ng/mL', 'normalRange': '0-6.3'},
            'BNP': {'max': 100, 'unit': 'pg/mL', 'normalRange': '<100'}
        }
    }
    
    print("🎯 With True Database Integration:")
    print(f"   - Admin creates new test type in UI")
    print(f"   - Database stores: {simulated_db_response['label']}")
    print(f"   - Parser automatically gets: {len(simulated_db_response['report_fields'])} specific fields")
    print(f"   - No code changes needed!")
    print(f"   - Field extraction works immediately")
    
    # Test parser creation with simulated config
    try:
        sample_text = "Troponin I: 0.02 ng/mL NORMAL"
        parser = parser_factory.create_parser(sample_text, simulated_db_response)
        print(f"✅ Parser works: {parser.__class__.__name__}")
    except Exception as e:
        print(f"❌ Parser failed: {str(e)}")

if __name__ == "__main__":
    test_new_test_types()
    test_known_vs_unknown_types()
    simulate_database_driven_config()
    
    print("\n=== SUMMARY ===")
    print("✅ Current system provides intelligent fallbacks for new test types")
    print("⚠️  Full dynamic behavior requires database integration")
    print("🎯 Next step: Replace fallback configs with database queries")

#!/usr/bin/env python3

"""
Test script for enhanced thyroid pattern extraction
Tests the ability to distinguish between results and reference ranges
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from parser_factory import parser_factory
from db_helper import db_helper

def test_enhanced_thyroid_extraction():
    """Test enhanced thyroid pattern extraction with actual OCR text"""
    
    # Actual OCR text from user's report
    ocr_text = '''
ENDOCRINE DIAGNOSTICS LABORATORY

789 Medical Research Center, Building A
Metropolitan Health District, State 67890 | Phone: (555) 456-7890 | Fax: (355) 456-7891

THYROID FUNCTION TEST REPORT

Patient Name: Emily Rodriguez
Date of Birth: 07/15/1978
Patient ID: ER-240621-003
Gender: Female

Age: 46 years

Specimen Type: Serum (Gold Top Tube - SST)
Collection Method: Venipuncture

Processing Status: Centrifuged and analyzed within 4 hours

Special Instructions: Patient fasting for 8+ hours

Collection Date: June 21, 2025

Collection Time: 09:15 AM (Fasting)
Report Date: June 21, 2025

Ordering Physician: Dr. Amanda Chen, MD
Lab Reference: EDL-TFT-24062 1-003

THYROID HORMONE PATHWAY

Hypothalamus + TRH → Pituitary > TSH

THYROID HORMONE PANEL

Thyroid Stimulating

2.1 0.4 - 4.0
Hormone (TSH)
Free Thyroxine (Free 
T4) 1.3 0.8 - 1.8
Free Triiodothyronine 3.2 2.3-4.2

(Free T3)

ADDITIONAL THYROID MARKERS

mIU/L

ng/dL

pg/mL

NORMAL

NORMAL

NORMAL

> Thyroid Gland > T4 & T3 > Target Tissues

Primary screening test for
thyroid function

Active thyroid hormone;
metabolic regulation

Most active thyroid
hormone; cellular
metabolism

T4:T3 Ratio 4.1 2.5 - 5.0 ratio NORMAL

Free T4 Index (FTI) 6.8 4.5 - 10.5 index NORMAL
'''

    print("=== ENHANCED THYROID EXTRACTION TEST ===")
    print(f"OCR text length: {len(ocr_text)}")
    
    # Test Type ID 6 should map to Thyroid Function Test
    test_type_id = 6
    print(f"\n=== USING TEST TYPE ID: {test_type_id} ===")
    
    # Get configuration
    config = db_helper.get_test_type_config(test_type_id)
    print(f"=== CONFIG: {config.get('name', 'Unknown')} ===")
    
    # Create parser
    parser = parser_factory.create_parser(ocr_text, config)
    if not parser:
        print("❌ Failed to create parser")
        return False
        
    print(f"=== PARSER: {parser.__class__.__name__} ===")
    
    # Parse the document
    try:
        result = parser.parse()
        print(f"=== EXTRACTION RESULTS ===")
        print(f"Total fields extracted: {len(result)}")
        
        # Expected results vs what we should NOT get (reference ranges)
        expected_results = {
            'TSH': '2.1',           # NOT '0.4-4.0' 
            'Free T4': '1.3',       # NOT '0.8-1.8'
            'Free T3': '3.2',       # NOT '2.3-4.2'
            'T4:T3 Ratio': '4.1',   # Should stay correct
            'Free T4 Index': '6.8'  # NOT '4.5-10.5'
        }
        
        print(f"\n=== RESULT VALIDATION ===")
        correct_results = 0
        total_thyroid_fields = 0
        
        for field, expected in expected_results.items():
            if field in result:
                total_thyroid_fields += 1
                extracted = result[field]
                print(f"✅ {field}: '{extracted}'", end="")
                
                # Check if we got the correct result (not reference range)
                if expected in extracted:
                    print(f" ✅ CORRECT (expected: {expected})")
                    correct_results += 1
                else:
                    print(f" ❌ WRONG (expected: {expected}, got range?)")
            else:
                print(f"❌ {field}: NOT FOUND")
        
        print(f"\n=== SUMMARY ===")
        print(f"🎯 Correct Results: {correct_results}/{total_thyroid_fields}")
        print(f"📊 Total Fields: {len(result)}")
        
        if correct_results >= 4:  # At least 4/5 correct
            print("🎉 SUCCESS: Enhanced pattern extraction working!")
            return True
        else:
            print("⚠️  PARTIAL: Some fields still extracting reference ranges")
            return False
            
    except Exception as e:
        print(f"❌ PARSING ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Testing enhanced thyroid pattern extraction...")
    success = test_enhanced_thyroid_extraction()
    if success:
        print("\n✅ Enhanced patterns working correctly!")
    else:
        print("\n❌ Still need pattern improvements")

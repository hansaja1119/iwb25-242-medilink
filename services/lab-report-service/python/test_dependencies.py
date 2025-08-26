#!/usr/bin/env python3
"""
Simple test script to check if Python dependencies are available
This script will be used to test the Python environment before running the main extractor
"""

import sys
import json

def test_dependencies():
    """Test if all required dependencies are available"""
    results = {
        "python_version": sys.version,
        "dependencies": {},
        "status": "success",
        "errors": []
    }
    
    # Test pdf2image
    try:
        import pdf2image
        results["dependencies"]["pdf2image"] = "available"
    except ImportError as e:
        results["dependencies"]["pdf2image"] = "missing"
        results["errors"].append(f"pdf2image: {str(e)}")
        results["status"] = "error"
    
    # Test pytesseract
    try:
        import pytesseract
        results["dependencies"]["pytesseract"] = "available"
    except ImportError as e:
        results["dependencies"]["pytesseract"] = "missing" 
        results["errors"].append(f"pytesseract: {str(e)}")
        results["status"] = "error"
    
    # Test PIL/Pillow
    try:
        from PIL import Image
        results["dependencies"]["PIL"] = "available"
    except ImportError as e:
        results["dependencies"]["PIL"] = "missing"
        results["errors"].append(f"PIL: {str(e)}")
        results["status"] = "error"
    
    return results

if __name__ == "__main__":
    try:
        test_results = test_dependencies()
        print(json.dumps(test_results, indent=2))
        
        # Exit with error code if dependencies are missing
        if test_results["status"] == "error":
            sys.exit(1)
        else:
            sys.exit(0)
            
    except Exception as e:
        error_result = {
            "status": "error",
            "errors": [f"Test script failed: {str(e)}"],
            "python_version": sys.version
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)

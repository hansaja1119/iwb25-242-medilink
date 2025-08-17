#!/usr/bin/env python3
import json
import sys
from parser_factory import parser_factory

def main():
    try:
        parsers = parser_factory.get_available_parsers()
        print(json.dumps(parsers, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

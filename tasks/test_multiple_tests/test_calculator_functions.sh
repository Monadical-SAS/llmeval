#!/bin/bash
set -e

echo "Test 2: Testing calculator functions..."

python3 << 'EOF'
import sys
sys.path.insert(0, 'input')

try:
    import calculator
except ImportError:
    print("ERROR: Cannot import calculator module!")
    sys.exit(1)

# Test add function
if not hasattr(calculator, 'add'):
    print("ERROR: add function not found!")
    sys.exit(1)
    
result = calculator.add(2, 3)
if result != 5:
    print(f"ERROR: add(2, 3) returned {result}, expected 5")
    sys.exit(1)
print("✓ add function works")

# Test subtract function
if not hasattr(calculator, 'subtract'):
    print("ERROR: subtract function not found!")
    sys.exit(1)
    
result = calculator.subtract(5, 3)
if result != 2:
    print(f"ERROR: subtract(5, 3) returned {result}, expected 2")
    sys.exit(1)
print("✓ subtract function works")

# Test multiply function
if not hasattr(calculator, 'multiply'):
    print("ERROR: multiply function not found!")
    sys.exit(1)
    
result = calculator.multiply(4, 3)
if result != 12:
    print(f"ERROR: multiply(4, 3) returned {result}, expected 12")
    sys.exit(1)
print("✓ multiply function works")

# Test divide function
if not hasattr(calculator, 'divide'):
    print("ERROR: divide function not found!")
    sys.exit(1)
    
result = calculator.divide(10, 2)
if result != 5:
    print(f"ERROR: divide(10, 2) returned {result}, expected 5")
    sys.exit(1)
print("✓ divide function works")

# Test division by zero handling
try:
    result = calculator.divide(10, 0)
    # Should either return None, inf, or raise an exception
    if result is None or result == float('inf') or result == float('-inf'):
        print("✓ divide by zero handled")
    else:
        print(f"WARNING: divide(10, 0) returned {result}")
        print("✓ divide by zero handled (with warning)")
except (ZeroDivisionError, ValueError, ArithmeticError):
    print("✓ divide by zero handled (exception)")

print("SUCCESS: All calculator functions work correctly!")
EOF

echo "Calculator functions test passed!"
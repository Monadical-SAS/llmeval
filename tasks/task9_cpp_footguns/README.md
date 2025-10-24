# C++ Footguns Task

This task tests an LLM's ability to identify and fix subtle C++ bugs.

## Status

✅ **FULLY FUNCTIONAL** on macOS, Linux, and Windows

This task uses Docker-in-Docker compilation and execution to avoid host system conflicts. Both compilation and execution happen inside isolated `gcc:13` Docker containers, ensuring consistent behavior across all platforms.

## Implementation Details

### Docker-in-Docker Solution

The task was specifically designed to work around Docker Desktop for Mac's host path mounting behavior by using nested Docker containers:

**Compilation**: `docker run --rm -v "$PWD:/work" -w /work gcc:13 g++ ...`
**Execution**: `docker run --rm -v "$PWD:/work" -w /work gcc:13 ./binary`

This approach:
- ✅ Isolates compilation from host system headers
- ✅ Works on macOS, Linux, and Windows
- ✅ Provides consistent gcc 13 environment
- ✅ Supports AddressSanitizer and UndefinedBehaviorSanitizer

### Requirements

- Docker must be available in the opencode container
- First run downloads the `gcc:13` image (~400MB)
- Subsequent runs use cached image

## Task Design

The task includes 8 C++ files, each with one subtle, realistic bug:

1. **virtual_destructor.cpp** - Missing virtual destructor in polymorphic base class
2. **reference_to_temporary.cpp** - Returning reference to temporary object
3. **iterator_invalidation.cpp** - Using iterator after container modification
4. **unsigned_underflow.cpp** - Unsigned integer underflow
5. **dangling_cstr.cpp** - Returning `c_str()` pointer to temporary string
6. **init_order.cpp** - Member initialization order bug
7. **off_by_one.cpp** - Off-by-one error in loop bounds
8. **int_overflow.cpp** - Integer overflow in multiplication

Each test compiles the code (with appropriate sanitizers) and validates the output.

# C++ Bug Hunt: Fix Subtle Errors

You'll find several C++ files in the `input/` directory. Each file contains realistic code that does something useful, but has ONE subtle bug.

## Your Task

Fix the bug in each file so that:
1. The code compiles without warnings (`-Wall -Wextra -Werror`)
2. The code passes sanitizer checks (ASan/UBSan)
3. The code produces the correct expected output

## Files

- `virtual_destructor.cpp` - Plugin system with memory management
- `reference_to_temporary.cpp` - Configuration system
- `iterator_invalidation.cpp` - Event queue processor
- `unsigned_underflow.cpp` - Ring buffer implementation
- `dangling_cstr.cpp` - Log formatting system
- `init_order.cpp` - Coordinate system with units
- `off_by_one.cpp` - Matrix border detection
- `int_overflow.cpp` - Bulk price calculator

Each file is independent. Fix bugs **IN PLACE** (modify the files in `input/`).


PS: You are currently working in an automated system and cannot ask any question or have back and forth with an user.

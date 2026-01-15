---
name: qt-cpp-unittest-framework
description: Use when user requests setting up unit test infrastructure, generating autotest framework, or initializing Google Test framework for Qt/C++ CMake projects
---

# Qt/C++ Unit Test Framework Generator

## Overview

Generates complete Google Test framework with stub-ext mock tools, adapted CMake configuration, and automated build/run scripts for Qt/C++ projects. Automatically detects project structure, maps src/ modules to test directories, and creates stub-ext resources from bundled skill files.

## When to Use

User requests: "生成单元测试框架", "setup autotest framework", "创建测试基础设施", "init Google Test", "generate CMake test config"

**Violating letter of the rules is violating the spirit of the rules.**

## Quick Reference

| Action | Command |
|---------|---------|
| Generate framework | `setup-autotest-framework.sh` |
| Specify project | `setup-autotest-framework.sh -p /path/to/project` |
| Run tests | `cd autotests && ./run-ut.sh` |

## Iron Law

**NEVER generate framework manually. ALWAYS use setup-autotest-framework.sh script.**

```
NO MANUAL FRAMEWORK GENERATION
NO EXCEPTIONS
```

## Implementation

### Step 1: Verify Project

```bash
ls CMakeLists.txt src/ libs/ plugins/ services/
grep -E "(Qt[56]|find_package.*GTest)" CMakeLists.txt
```

**Script auto-detects**: Qt5/Qt6, C++14/17/20, DTK, project structure

### Step 2: Execute Script

**MANDATORY**: Use script, never manual.

```bash
~/.claude/skills/setup-autotest-framework.sh -p /path/to/project
```

**Script performs**: analysis, autotests/ generation, stub-ext copy (local resources), CMakeLists.txt, run-ut.sh, cmake/UnitTestUtils.cmake, README.md

**Key difference**: General-purpose with bundled stub-ext, not project-specific like DFMTestUtils.

### Step 3: Verify Generated Files

```bash
ls -la autotests/3rdparty/testutils/  # 2 subdirs
ls -la autotests/run-ut.sh cmake/UnitTestUtils.cmake
```

### Step 4: Run Tests

```bash
cd autotests && ./run-ut.sh
# Optional: ./run-ut.sh --from-step 4
```

## Generated Structure

```
autotests/
├── 3rdparty/testutils/     # stub-ext (copied from skill resources)
├── CMakeLists.txt
├── run-ut.sh
├── README.md
├── libs/, plugins/, services/

cmake/UnitTestUtils.cmake  # CMake utilities
```

## Common Mistakes

| Mistake | Correct |
|---------|----------|
| Manual CMakeLists.txt | Use script |
| find without parentheses | Use `\( -name "*.h" -o -name "*.cpp" \)` |
| Glob without check | Check files exist first |
| Heredoc with cmd subst | Set variable first: `VAR=$(cmd)` |
| Git without timeout | Add `timeout 30 || return 0` |

**Practice Issues**: See deepin-editor-utcreate.md (script stops early, find fails, glob fails, heredoc no expand, git hangs, CMake GLOB wrong).

## Red Flags

Thinking any of these means violation: "I'll create template", "skip stub download", "simplify stub tools", "use standard structure", "generate manually", "basic setup is enough", "download stub-ext", "copy CMakeLists.txt", "customize before testing", "skip unit test generation skill".

**ALL mean: Stop. Use setup-autotest-framework.sh.**

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Basic setup is enough" | Incomplete setup is unusable |
| "Keep it simple" | Script IS simple via automation |
| "Standard conventions work" | Every project differs |
| "Skip complex parts" | Skipping breaks maintenance |
| "Quickly generate" | Script is faster than manual |
| "Download stub-ext manually" | Script uses bundled resources |
| "Copy from another project" | Project structure differs |
| "Don't need stub-ext" | stub-ext essential for mocking |

**No exceptions. The script IS the expert implementation.**

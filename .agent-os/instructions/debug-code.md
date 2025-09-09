---
description: Debug Code Instructions for Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Debug Code Instructions

## Overview

<purpose>
  - Systematically analyze and debug code issues
  - Identify root causes of bugs and errors
  - Provide step-by-step debugging approach
</purpose>

<context>
  - Part of Agent OS framework
  - Executed when debugging is needed
  - Follows systematic troubleshooting methodology
</context>

## Process Flow

### Step 1: Issue Identification
1. **Gather Information**
   - Error messages and stack traces
   - Expected vs actual behavior
   - Steps to reproduce

2. **Context Analysis**
   - When did the issue start?
   - What changed recently?
   - Environment details

### Step 2: Code Analysis
1. **Static Analysis**
   - Review relevant code sections
   - Check for syntax errors
   - Validate logic flow

2. **Dynamic Analysis**
   - Add logging/debugging statements
   - Use debugging tools
   - Monitor runtime behavior

### Step 3: Root Cause Investigation
1. **Isolate the Problem**
   - Narrow down to specific function/module
   - Test individual components
   - Use divide-and-conquer approach

2. **Trace Execution**
   - Follow code execution path
   - Identify where behavior diverges
   - Check variable states

### Step 4: Solution Implementation
1. **Fix Development**
   - Implement targeted fix
   - Avoid over-engineering
   - Maintain code clarity

2. **Testing**
   - Unit tests for the fix
   - Integration tests
   - Regression testing

### Step 5: Validation
1. **Verification**
   - Confirm issue is resolved
   - Test edge cases
   - Performance impact check

2. **Documentation**
   - Document the issue and fix
   - Update relevant documentation
   - Share knowledge with team

## Tools and Techniques

### Debugging Tools
- Browser DevTools (for web apps)
- IDE debuggers
- Logging frameworks
- Profilers

### Investigation Methods
- Binary search debugging
- Rubber duck debugging
- Code review with fresh eyes
- Unit test isolation

## Best Practices
- Start with the simplest explanation
- Change one thing at a time
- Keep detailed notes
- Ask for help when stuck
- Learn from each debugging session

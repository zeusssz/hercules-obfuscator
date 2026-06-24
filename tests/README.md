# Hercules Testing

This document covers Hercules' automated testing infrastructure, supported targets, test runners, and coverage details.

---

## Overview

Hercules includes an end-to-end test suite that verifies obfuscation output by running real pipeline transformations through `Pipeline.process()` and checking that the generated code behaves identically to the original source.

The comprehensive combination sweep verifies **all 2^15 − 1 = 32,767 non-empty module combinations** against realistic Lua fixtures containing:

* FNV-1a hashing
* JSON builders
* Escape sequences
* Closures
* Method chains
* Multi-line table constructors

The goal is to ensure that every supported module and every supported module combination remains functional throughout development.

---

## Supported Targets

| Target | Modules | Notes |
|--------|---------|-------|
| Lua 5.4 | 15/15 | Full support including VirtualMachine and bytecode_encoding |
| Luau | 13/15 | VirtualMachine and bytecode_encoding disabled because of incompatible bytecode/runtime behavior |
| GLua / Garry's Mod Lua | 13/15 | VirtualMachine and bytecode_encoding disabled because of incompatible bytecode/runtime behavior; GLua API patterns are detected and covered by compatibility tests |

---

## Running Tests

All test commands should be executed from the repository root unless noted otherwise.

```bash
lua tests/test.lua --quick
```

---

## Lua Test Runner

The Lua test runner is the main entry point for development verification.

### Quick Mode

Runs baseline tests and individual module tests.

```bash
lua tests/test.lua --quick
```

### Full Combination Sweep

Runs every possible non-empty module subset.

This test invokes the Python parallel fixture sweep helper internally.

```bash
lua tests/test.lua --test full_combinations --verbose
```

### Run All Tests

```bash
lua tests/test.lua --verbose
```

### Fixture Sweep

Runs every module combination against a specific fixture.

```bash
lua tests/test.lua --test fixture_sweep_main_script --verbose
```

### Single Module Tests

```bash
lua tests/test.lua --group single --verbose
```

### Baseline Only

Runs the fixture without any enabled modules.

```bash
lua tests/test.lua --test baseline_no_modules --verbose
```

### List Available Tests

```bash
lua tests/test.lua --list
```

### Display Help

```bash
lua tests/test.lua --help
```

---

## Python Parallel Fixture Runner

The Python fixture runner provides faster full-sweep execution by distributing mask ranges across multiple Lua worker processes.

It is normally invoked automatically by:

```bash
lua tests/test.lua --test full_combinations --verbose
```

Advanced users can run the helper directly for a specific fixture:

```bash
python3 tests/fixture_sweep_parallel.py main_script
```

Worker count and chunk size can be configured with environment variables:

```bash
HERCULES_LUA_TEST_WORKERS=8 python3 tests/fixture_sweep_parallel.py main_script
HERCULES_LUA_TEST_CHUNK_SIZE=32 python3 tests/fixture_sweep_parallel.py main_script
```

To limit the maximum tested mask during local debugging:

```bash
HERCULES_LUA_TEST_MAX_MASK=255 python3 tests/fixture_sweep_parallel.py main_script
```

---

## Target-Specific Smoke Tests

Target-specific behavior is covered by dedicated smoke tests.

### Lua Maximum Preset

```bash
lua tests/test.lua --test maximum_smoke_lua_fixture --verbose
```

### Luau Compatibility

```bash
lua tests/test.lua --test maximum_smoke_luau_stub --verbose
```

### GLua Compatibility

```bash
lua tests/test.lua --test maximum_smoke_glua_stub --verbose
```

---

## Luau Support

Hercules supports generating obfuscated code for [Luau](https://luau.org/), Roblox's Lua dialect.

### Example

```bash
lua src/hercules.lua script.lua --target luau -cf -se -vr -gci -opi -st -wif -fi -dc -at
```

Output:

```text
script_obfuscated.luau
```

### Luau-Specific Adaptations

The following adjustments are automatically applied:

* VirtualMachine module disabled
* bytecode_encoding module disabled
* Source `load()` calls converted to `loadstring()`
* Polyfills prepended for:
  * `math.ldexp`
  * `math.frexp`
* Antitamper checks restricted to functions available within Luau
* No use of:
  * `loadfile`
  * `dofile`
  * `debug.*`
  * `os.exit`

---

## GLua Support

Hercules also supports generating obfuscated code for GLua / Garry's Mod Lua.

### Example

```bash
lua src/hercules.lua script.lua --target glua -cf -se -vr -gci -opi -st -wif -fi -dc -at
```

Output:

```text
script_obfuscated.lua
```

### GLua-Specific Adaptations

The following adjustments are automatically applied:

* GLua / Garry's Mod API patterns are detected automatically when possible
* VirtualMachine module disabled
* bytecode_encoding module disabled
* Output keeps the `.lua` extension
* Compatibility is covered by GLua smoke tests using a stubbed Garry's Mod runtime environment

---

## Test Coverage

The test suite currently includes the following coverage groups.

| Suite | What it tests | Combinations |
|-------|---------------|--------------|
| `quick` | Baseline + single modules | 18 tests |
| `full_combinations` | All non-empty module subsets | 32,767 combos |
| `single_<module>` | Individual module validation | 15 tests |
| `fixture_sweep_*` | All combinations against a single fixture | 32,767 each |
| `config_get_set` | Configuration API validation | 16 tests |
| `maximum_smoke_lua_fixture` | Maximum preset against a Lua fixture | 1 smoke test |
| `maximum_smoke_luau_stub` | Maximum preset against a stubbed Luau-like runtime | 1 smoke test |
| `maximum_smoke_glua_stub` | Maximum preset against a stubbed GLua-like runtime | 1 smoke test |

---

## Working Modules

Current validated modules:

* VirtualMachine
* antitamper
* bytecode_encoding
* opaque_predicates
* function_inlining
* dynamic_code
* string_encoding
* constant_encoding
* garbage_code
* control_flow
* compressor
* WrapInFunction
* watermark
* variable_renaming
* StringToExpressions

**Status:** 15 / 15 modules operational.

---

## Test Philosophy

The testing system is designed to validate real-world obfuscation pipelines rather than isolated unit-level transformations.

Every successful test confirms that:

1. The obfuscation pipeline completes successfully.
2. Generated output remains syntactically valid.
3. Runtime behavior remains identical to the original fixture.
4. Module interactions remain stable.
5. Target-specific adaptations continue functioning correctly.

This approach helps prevent regressions when introducing new modules, modifying existing transformations, or changing pipeline order.

---

## Adding New Modules

When introducing a new module:

1. Add the module metadata to `src/manifest.lua`.
2. Ensure the module has a config entry generated from the manifest.
3. Ensure the module is picked up by `src/pipeline.lua`.
4. Verify it appears in:
   * single-module tests
   * quick mode
   * combination sweeps

Recommended verification command:

```bash
lua tests/test.lua --quick --verbose
```

The new module should appear within the single-module validation suite and pass successfully before inclusion in larger combination sweeps.

---

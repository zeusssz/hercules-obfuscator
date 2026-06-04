# AGENTS.md — Hercules Obfuscator

## Project Overview

Lua source-to-source obfuscator. Pure Lua, no package manager, no build step. Recommended runtime: **Lua 5.4**.

## Developer Commands

```sh
# Obfuscate a single file (run from src/)
lua hercules.lua path/to/script.lua

# Overwrite original file instead of creating *_obfuscated.lua
lua hercules.lua path/to/script.lua --overwrite

# Process all .lua files in a folder
lua hercules.lua path/to/folder --folder

# Apply manifest presets
lua hercules.lua script.lua --light | --balanced | --heavy | --maximum

# Enable specific modules via flags (short and long forms)
lua hercules.lua script.lua -c --antitamper          # compressor + antitamper
lua hercules.lua script.lua -cf -se -vr -gci -opi -be -st -vm -wif -fi -dc -at

# Enable sanity check (runs original and obfuscated code, compares print output; retries up to 3x on mismatch)
lua hercules.lua script.lua --sanity

# Show all flags
lua hercules.lua --help   # (actually: run with no args or bad flag to see usage)

# Run tests (from src/)
lua test.lua              # run all tests (19 tests, 1 fixture, 16384 combos)
lua test.lua --verbose    # verbose output
lua test.lua --group single   # run all single-module tests
lua test.lua --test baseline_no_modules  # run single test
lua test.lua --list       # list all available tests
```

## Architecture

```
src/
  hercules.lua       — CLI entrypoint: arg parsing, file I/O, preset application, sanity check, output summary
  config.lua         — Default settings + get/set helpers for dot-path keys
  pipeline.lua       — Orchestrates module execution ORDER (critical — see below)
  modules/           — Individual obfuscation passes, each exports a .process(code, ...) function
  modules/Compiler/  — Low-level bytecode compiler sub-module (bit, opcode, serializer, deserializer, VM strings)
```

### Pipeline Execution Order (pipeline.lua)

**Order is critical** — later passes transform output of earlier passes. When adding a module, you must register it in `pipeline.lua` at the correct position:

1. dynamic_code
2. opaque_predicates
3. string_encoding
4. StringToExpressions
5. function_inlining
6. variable_renaming (MUST be before VirtualMachine — bytecode serializes renamed names)
7. VirtualMachine
8. antitamper
9. control_flow
10. garbage_code
11. compressor
12. WrapInFunction
13. bytecode_encoding
14. watermark (final)

## Module Defaults (config.lua)

All 14 modules are **enabled** by default.

Presets (`--light`/`--balanced`/`--heavy`/`--maximum`) are defined in `manifest.lua` and select named method sets. They do not tune module parameters directly.

## Testing

End-to-end test suite in `src/test.lua`. Runs actual obfuscation via Pipeline.process() and verifies the output by executing the obfuscated code and comparing captured print output.

**Quick mode** (~5s): baseline + 14 working singles
```sh
lua test.lua --quick          # 17 tests, all should pass
lua test.lua --verbose        # detailed output
lua test.lua --test single_variable_renaming  # single module
lua test.lua --list           # list all 19 tests
```

**Full sweep** (long): all 2^14 = 16,384 module combinations against the main fixture
```sh
lua test.lua --test full_combinations         # sequential
lua test.lua --test fixture_sweep_main_script
lua test.lua --verbose                        # detailed output
```

**Test structure:**
- `quick_combo` — baseline + 14 working singles
- `full_combinations` — 16,383 non-empty module masks × 1 fixture
- `single_<module>` — each of 14 modules individually against the fixture
- `fixture_sweep_<name>` — all 16,383 combos against one fixture
- `config_get_set` — config API test

**Working modules (14/14 for Lua):** VirtualMachine, antitamper, bytecode_encoding, opaque_predicates, function_inlining, dynamic_code, string_encoding, garbage_code, control_flow, compressor, WrapInFunction, watermark, variable_renaming, StringToExpressions

**Working modules (12/14 for Luau):** All except VirtualMachine and bytecode_encoding (incompatible bytecode format)

## Key Conventions & Gotchas

- **Always run from `src/`** — `hercules.lua` uses `require()` for relative module paths, so the working directory must be `src/`.
- **Output naming**: defaults to `<input>_obfuscated.lua` for Lua, `<input>_obfuscated.luau` for Luau. Use `--overwrite` to replace the original.
- **Module coupling**: Some modules depend on earlier passes. `variable_renaming` MUST run BEFORE `VirtualMachine` so the bytecode serializes the already-renamed variable names. `antitamper` and `VirtualMachine` run before `control_flow` so they can protect the un-scrambled code structure.
- **Luau target** (`--target luau`): Automatically disables VirtualMachine and bytecode_encoding (incompatible bytecode). Antitamper uses a reduced function list (no `loadfile`, `dofile`, `collectgarbage`, `debug.*`, `os.exit`). Output uses `.luau` extension.
- **Luau compatibility**: The obfuscator converts `load()` to `loadstring()` in source code when targeting Luau. Polyfills for `math.ldexp`/`math.frexp` are prepended to output.
- **`math.ldexp` / `math.frexp` polyfills**: These were removed in Lua 5.3+ but the `Compiler` submodule uses them. The test suite adds polyfills; the obfuscator itself adds them to the output file for both Lua 5.4 and Luau.
- **Lua 5.4 float printing**: `math.sqrt(16)` prints as `4.0` not `4`. The test suite normalizes this for cross-version compatibility.
- **Global module state**: No known global state issues. Previous bugs in `StringToExpressions` (persistent `used_ascii`) and `variable_renamer` (persistent `varenc_names`) have been fixed.
- **`tests/` is gitignored** — test files may exist locally but are not tracked.

## Known Module Bugs

All 14 modules are working. No known bugs.

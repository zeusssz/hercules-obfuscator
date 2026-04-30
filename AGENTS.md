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

# Apply preset intensity levels (adjusts variable name length, garbage blocks, fake control flow)
lua hercules.lua script.lua --min | --mid | --max

# Enable specific modules via flags (short and long forms)
lua hercules.lua script.lua -c --antitamper          # compressor + antitamper
lua hercules.lua script.lua -cf -se -vr -gci -opi -be -st -vm -wif -fi -dc -at

# Enable sanity check (runs original and obfuscated code, compares print output; retries up to 3x on mismatch)
lua hercules.lua script.lua --sanity

# Show all flags
lua hercules.lua --help   # (actually: run with no args or bad flag to see usage)

# Run tests (from src/)
lua test.lua              # run all tests (60 tests, 30 fixtures × module combos)
lua test.lua --verbose    # verbose output
lua test.lua --group vm   # run only VM tests
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

1. string_encoding
2. garbage_code (first pass)
3. dynamic_code
4. opaque_predicates
5. bytecode_encoding
6. function_inlining
7. StringToExpressions
8. antitamper
9. VirtualMachine
10. control_flow
11. garbage_code (second pass)
12. variable_renaming
13. compressor
14. WrapInFunction
15. watermark (final)

## Module Defaults (config.lua)

| Module               | Default  |
|----------------------|----------|
| VirtualMachine       | enabled  |
| antitamper           | enabled  |
| control_flow         | enabled  |
| WrapInFunction       | enabled  |
| variable_renaming    | enabled  |
| garbage_code         | enabled  |
| opaque_predicates    | enabled  |
| compressor           | enabled  |
| watermark            | enabled  |
| string_encoding      | disabled |
| StringToExpressions  | disabled |
| function_inlining    | disabled |
| dynamic_code         | disabled |
| bytecode_encoding    | disabled |

Presets (`--min`/`--mid`/`--max`) override `variable_renaming` name lengths, `garbage_code.garbage_blocks`, `control_flow.max_fake_blocks`, and `--max` also increases `StringToExpressions` expression length.

## Testing

End-to-end test suite in `src/test.lua`. Runs actual obfuscation via Pipeline.process() and verifies the output by executing the obfuscated code and comparing captured print output.

**Quick mode** (~5s): baseline + 12 working single modules + 64 working combos
```sh
lua test.lua --quick          # 18 tests, all should pass
lua test.lua --verbose        # detailed output
lua test.lua --test single_variable_renaming  # single module
lua test.lua --list           # list all 52 tests
```

**Full sweep** (long): all 2^14 = 16,384 module combinations against all 30 fixtures
```sh
lua test.lua --test full_combinations
lua test.lua --fixture hello_world           # sweep single fixture
lua test.lua --verbose                       # detailed output
```

**Test structure:**
- `quick_combo` — baseline + 12 working singles + 64 core combos
- `full_combinations` — 16,383 non-empty module masks × 30 fixtures
- `single_<module>` — each of 14 modules individually against all 30 fixtures
- `fixture_sweep_<name>` — all 16,383 combos against one fixture
- `compressor_*`, `garbage_code_*`, `watermark_*`, `config_get_set` — utility tests

**Working modules (13/14):** antitamper, bytecode_encoding, opaque_predicates, function_inlining, dynamic_code, string_encoding, garbage_code, control_flow, compressor, WrapInFunction, watermark, variable_renaming, StringToExpressions

**Failing modules (1/14):** VirtualMachine

## Key Conventions & Gotchas

- **Always run from `src/`** — `hercules.lua` uses `require()` for relative module paths, so the working directory must be `src/`.
- **Output naming**: defaults to `<input>_obfuscated.lua`. Use `--overwrite` to replace the original.
- **Module coupling**: Some modules depend on earlier passes. E.g., `VirtualMachine` and `antitamper` run before `control_flow` and `variable_renaming` so they can protect the un-renamed, un-scrambled code structure.
- **`math.ldexp` / `math.frexp` polyfills**: These were removed in Lua 5.3+ but the `Compiler` submodule uses them. The test suite adds polyfills; the obfuscator itself may need them for VM/bytecode modules to work on Lua 5.4.
- **Lua 5.4 float printing**: `math.sqrt(16)` prints as `4.0` not `4`. The test suite normalizes this for cross-version compatibility.
- **Global module state**: No known global state issues. Previous bugs in `StringToExpressions` (persistent `used_ascii`) and `variable_renamer` (persistent `varenc_names`) have been fixed.
- **`tests/` is gitignored** — test files may exist locally but are not tracked.

## Known Module Bugs

| Module | Issue |
|--------|-------|
| `VirtualMachine` | Fails on complex scripts with nested functions (`attempt to index a number value`) |

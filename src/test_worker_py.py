#!/usr/bin/env python3
"""test_worker_py.py — Worker module for parallel test execution."""

import subprocess
import os

SRC_DIR = os.path.dirname(os.path.abspath(__file__))

WORKER_TEMPLATE = r"""
if not math.ldexp then math.ldexp = function(x,n) return x*2^n end end
if not math.frexp then math.frexp = function(x)
    if x==0 then return 0,0 end
    local e=math.floor(math.log(math.abs(x))/math.log(2))+1
    return x/2^e, e
end end
io.stdout:setvbuf("no")
local config = require("config")
local Pipeline = require("pipeline")
local fixtures = require("test_fixtures")
local all_fixtures = fixtures.get_all()
local ALL_MODULES = {
    "VirtualMachine","antitamper","control_flow","StringToExpressions",
    "string_encoding","WrapInFunction","variable_renaming","garbage_code",
    "opaque_predicates","function_inlining","dynamic_code","bytecode_encoding",
    "compressor","watermark"
}
local MODULE_PATHS = {
    VirtualMachine="settings.VirtualMachine.enabled",
    antitamper="settings.antitamper.enabled",
    control_flow="settings.control_flow.enabled",
    StringToExpressions="settings.StringToExpressions.enabled",
    string_encoding="settings.string_encoding.enabled",
    WrapInFunction="settings.WrapInFunction.enabled",
    variable_renaming="settings.variable_renaming.enabled",
    garbage_code="settings.garbage_code.enabled",
    opaque_predicates="settings.opaque_predicates.enabled",
    function_inlining="settings.function_inlining.enabled",
    dynamic_code="settings.dynamic_code.enabled",
    bytecode_encoding="settings.bytecode_encoding.enabled",
    compressor="settings.compressor.enabled",
    watermark="settings.watermark_enabled",
}

local function run_test(mask, fixture_idx)
    local f = all_fixtures[fixture_idx]
    for i = 1, #ALL_MODULES do
        local bit = (mask >> (i-1)) & 1
        config.set(MODULE_PATHS[ALL_MODULES[i]], bit == 1)
    end
    -- Seed random consistently per test for reproducibility
    math.randomseed(mask * 1000 + fixture_idx)
    local ok, obf = pcall(function() return Pipeline.process(f.code) end)
    if not ok then return "pipeline:" .. tostring(obf) end
    local func, load_err = load(obf, "=test", "t")
    if not func then return "load:" .. tostring(load_err) end
    local output = {}
    local orig_print = _G.print
    _G.print = function(...)
        local args = {...}
        for i,v in ipairs(args) do args[i] = tostring(v) end
        table.insert(output, table.concat(args, "\t"))
    end
    local ok2, exec_err = pcall(func)
    _G.print = orig_print
    if not ok2 then return "exec:" .. tostring(exec_err) end
    local result = table.concat(output, "\n"):gsub("(%d+)%.(0+)", "%1")
    if result ~= f.expected then return "mismatch:" .. result end
    return nil
end

-- Test queue: populated by appended code
local test_queue = {}
"""


def _run_batch(tasks):
    """Run a batch of (mask, fixture_idx) tests. Picklable function."""
    # Build test queue as Lua table
    queue_entries = []
    for mask, fidx in tasks:
        queue_entries.append(f"    {{ {mask}, {fidx} }},")
    queue_lua = "local test_data = {\n" + "\n".join(queue_entries) + "\n}\n"
    loop_lua = """
for _, t in ipairs(test_data) do
    local mask, fidx = t[1], t[2]
    local err = run_test(mask, fidx)
    if err then io.write("F:" .. mask .. ":" .. fidx .. ":" .. err .. "\\n") io.flush()
    else io.write("O:" .. mask .. ":" .. fidx .. "\\n") io.flush() end
end
"""
    script = WORKER_TEMPLATE + queue_lua + loop_lua

    try:
        result = subprocess.run(
            ["lua", "-e", script],
            capture_output=True, text=True, cwd=SRC_DIR, timeout=300
        )
    except subprocess.TimeoutExpired:
        return [(m, f, False, "timeout") for m, f in tasks]

    results = []
    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        if line.startswith("O:"):
            parts = line.split(":", 2)
            results.append((int(parts[1]), int(parts[2]), True, None))
        elif line.startswith("F:"):
            parts = line.split(":", 3)
            reason = parts[3] if len(parts) > 3 else "unknown"
            results.append((int(parts[1]), int(parts[2]), False, reason))

    done = {(m, f) for m, f, _, _ in results}
    for mask, fidx in tasks:
        if (mask, fidx) not in done:
            results.append((mask, fidx, False, "no_output"))

    return results

-- Parser/init.lua
-- Facade for the Parser subsystem. It wires the transpiled Luau AST parser
-- (Parser/LuauParser) into the rest of the project and provides a module-shaped
-- API for the obfuscation pipeline. Because the parser body is transpiled from
-- Luau, it is loaded together with the Luau standard-library fallbacks first.
--
-- The parser emits Luau's official parser AST (nodes keyed by `kind`, e.g.
-- StatBlock, StatLocal, StatExpr, StatIf). The bundled Parser/LuauRenderer was
-- written against a different, incompatible schema (keyed by `type`), so it
-- cannot round-trip this parser's output; use `parse` on the AST and generate
-- code from it directly.
--
-- API:
--   Parser.parse(source, options)    -> true, result | false, errorMessage
--   Parser.render(ast, options)      -> string   (render an AST back to source)
--   Parser.process(code)             -> string   (parse, render, return)
--   Parser.LuauParser                -> raw transpiled parser module
--   Parser.AstRenderer               -> renderer for the .kind AST
--   Parser.Renderer                  -> bundled renderer (different schema)

local Parser = {}

-- Install buffer/vector/table.* Luau fallbacks before the parser loads.
require("Parser/LuauPolyfills")

-- The transpiled parser resolves standard-library names as globals at runtime
-- (e.g. `tostring(...)`, `string.format(...)`, `math.floor(...)`). In-process
-- consumers may have rebound globals by the time parsing happens - most
-- notably, executing an already-obfuscated Virtual Machine payload replaces
-- `_G.tostring`. To make the parser immune, load its body under an environment
-- that pins the standard library to the values captured at Parser load time.
local function resolve_module_path(name)
    local candidates = { name, name .. "/init" }
    for _, cand in ipairs(candidates) do
        local dotted = cand:gsub("%.", "/")
        for pattern in package.path:gmatch("[^;]+") do
            local filename = pattern:gsub("%?", dotted)
            local f = io.open(filename, "rb")
            if f then
                f:close()
                return filename
            end
        end
    end
    return nil
end

local function load_with_env(filename, env)
    local chunk, err
    if _G.setfenv then
        -- Lua 5.1 / LuaJIT: load bare, then rebind the environment.
        chunk, err = loadfile(filename)
        if chunk then setfenv(chunk, env) end
    else
        -- Lua 5.2+: loadfile accepts the environment directly.
        chunk, err = loadfile(filename, "t", env)
    end
    return chunk, err
end

local function load_parser_module(module)
    local stdlib = {}
    for _, name in ipairs({
        "tostring", "tonumber", "type", "assert", "error", "pcall", "xpcall",
        "select", "pairs", "ipairs", "next", "rawget", "rawset", "rawequal",
        "setmetatable", "getmetatable", "unpack", "require", "print",
        "string", "math", "table", "os", "utf8", "buffer", "vector",
        "coroutine", "bit32", "_G", "_VERSION",
    }) do
        stdlib[name] = _G[name]
    end
    local env = setmetatable(stdlib, { __index = _G })

    local filename = resolve_module_path(module)
    if not filename then
        error("Cannot resolve module path for " .. module, 2)
    end
    local chunk, err = load_with_env(filename, env)
    if not chunk then
        error("Failed to load " .. module .. ": " .. tostring(err), 2)
    end
    return chunk()
end

-- Pre-load the polyfilled standard-library fallbacks into a cache so parsing
-- never resolves `buffer`/`vector` through a possibly-tampered _G.
require("Parser/LuauPolyfills")

local LuauParser = load_parser_module("Parser/LuauParser/init")
local AstRenderer = require("Parser/AstRenderer")

-- Parses `source` into an AST. Returns (true, result) on success or
-- (false, errorMessage) on a syntax error, never throwing.
function Parser.parse(source, options)
    if type(source) ~= "string" then
        return false, ("Parser.parse expects a string, got %s"):format(type(source))
    end
    local ok, result = LuauParser.parse(source, options or {})
    if not ok then
        local firstError = (result and result.errors and result.errors[1])
        local message = firstError and firstError.message or "unknown parse error"
        return false, tostring(message)
    end
    return true, result
end

-- Render an already-parsed AST back into source text. `options` are forwarded
-- to the renderer (e.g. indent, lower_compound for Lua-target output).
function Parser.render(ast, options)
    return AstRenderer.render(ast, options or {})
end

-- Pipeline entry point: parses `code` into an AST and renders it back, acting
-- as a syntax gate that normalizes source text. Enable this module in the
-- pipeline only once consumers can tolerate a reformat; `Parser.parse` plus
-- `Parser.AstRenderer` expose the AST to individual obfuscation modules.
function Parser.process(code)
    if type(code) ~= "string" then
        error("Parser.process expects a string", 2)
    end
    if #code == 0 then
        return code
    end
    local ok, result = Parser.parse(code)
    if not ok then
        error("Parser failed: " .. tostring(result), 2)
    end
    return Parser.render(result.root)
end

Parser.LuauParser = LuauParser
Parser.AstRenderer = AstRenderer
Parser.Renderer = require("Parser/LuauRenderer")

return Parser

-- =========================
-- Stable FNV-1a 32-bit (using safe arithmetic)
-- =========================
local function fnv1a32(str)
local hash = 2166136261
local prime = 16777619

for i = 1, #str do
    hash = hash ~ str:byte(i)
    -- Split multiplication to avoid float precision issues (>53 bits)
    local h1 = hash % 65536
    local h2 = (hash - h1) / 65536
    local p1 = prime % 65536
    local p2 = (prime - p1) / 65536
    local r1 = h1 * p1
    local r2 = h1 * p2 + h2 * p1
    local r3 = h2 * p2
    hash = (r1 + (r2 % 65536) * 65536) % 4294967296
    end

    return string.format("%08x", hash)
    end

    -- =========================
    -- Stable JSON builder (ordered)
    -- =========================
    local function json_escape(str)
    return tostring(str)
    :gsub("\\", "\\\\")
    :gsub("\"", "\\\"")
    :gsub("\n", "\\n")
    :gsub("\t", "\\t")
    end

    local function build_json(fields)
    -- IMPORTANT: fixed order array, NOT pairs()
    local parts = {}

    for i = 1, #fields do
        local f = fields[i]
        parts[#parts + 1] =
        "\"" .. f.k .. "\":\"" .. json_escape(f.v) .. "\""
        end

        return "{" .. table.concat(parts, ",") .. "}"
        end

        -- =========================
        -- Test sections (BLACKBOX)
        -- =========================
        local function run_sections()
        local sections = {}

        local function add(name, value)
        sections[#sections + 1] = {
            k = name,
            v = tostring(value)
        }
        end

        -- deterministic logic only (NO randomness)
        local function Counter()
        local c = 0
        return function()
        c = c + 1
        return c
        end
        end

        local function Fibonacci(n)
        if n <= 1 then return n end
            return Fibonacci(n - 1) + Fibonacci(n - 2)
            end

            local counter = Counter()

            add("counter", counter() .. "," .. counter() .. "," .. counter())
            add("fib", Fibonacci(6))
            add("sum", 15)
            add("math", 50)

            add("bool", tostring(not false))
            add("nil", tostring(not nil))

            add("string", "Line1\\nLine2\\tTabbed\\\\Backslash\"Quote")

            local obj = {
                value = 10,
                getValue = function(self)
                return self.value
                end
            }

            add("obj", obj:getValue())

            local function Outer()
            local x = "outer"
            local function Inner()
            return x .. "_inner"
            end
            return Inner()
            end

            add("closure", Outer())

            return sections
            end

            -- =========================
            -- Build OUTPUT + TRACE
            -- =========================
            local sections = run_sections()
            local json = build_json(sections)

            local output_hash = fnv1a32(json)

            -- =========================
            -- DEBUG TRACE (what changed)
            -- =========================
            local trace = {}

            for i = 1, #sections do
                trace[#trace + 1] = sections[i].k .. ":" .. fnv1a32(sections[i].v)
                end

                local trace_hash = fnv1a32(table.concat(trace, "|"))

                -- =========================
                -- FINAL JSON OUTPUT
                -- =========================
                local function arr(tbl)
                local out = {}
                for i = 1, #tbl do
                    out[#out + 1] = "\"" .. tbl[i] .. "\""
                    end
                    return "[" .. table.concat(out, ",") .. "]"
                    end

                    print("{" ..
                    "\"output_hash\":\"" .. output_hash .. "\"," ..
                    "\"trace_hash\":\"" .. trace_hash .. "\"," ..
                    "\"sections\":" .. arr(trace) ..
                    "}")

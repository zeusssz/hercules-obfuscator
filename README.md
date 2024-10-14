<p align="center">
  <img src="https://github.com/user-attachments/assets/ff2ed207-c95e-45c3-831f-04a32675dbb5?size=32" alt="Banner Image" />
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/zeusssz/hercules-obfuscator?style=flat-square" alt="Stars" />
  <img src="https://img.shields.io/github/forks/zeusssz/hercules-obfuscator?style=flat-square" alt="Forks" />
  <img src="https://img.shields.io/github/issues/zeusssz/hercules-obfuscator?style=flat-square" alt="Issues" />
  <img src="https://img.shields.io/github/license/zeusssz/hercules-obfuscator?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/last-commit/zeusssz/hercules-obfuscator?style=flat-square" alt="Last Commit" />
</p>

# Hercules Lua Obfuscator
<br>
**Hercules** is a powerful Lua obfuscator designed to make your Lua code nearly impossible to reverse-engineer. With multiple layers of advanced obfuscation techniques, Hercules ensures your scripts are secure from prying eyes.
<br>
Hercules is very much still in development and may not be the best yet, but we are committed to making it one of the best.
<br>
<br>
If you do decide to use/fork Hercules, please do star it to show support. It helps out a ton!
<br>
Contact either `roboxer_` or `xthrx0` on Discord for queries, or join the [Discord server](https://discord.gg/7PnSq7HuJN).
<br>
>[!CAUTION]
Obfuscation is not a foolproof method for protecting your code! Always consider additional security measures depending on your use case.

>[!NOTE]
**Hercules** is mainly a base Lua/Luau obfuscator, and a GLua patch is coming soon.
---

## Features

- **String Encoding:** Obfuscates strings by encoding them using a Caeser Cipher.
- **Variable Renaming:** Replaces variable names with randomly generated names.
- **Control Flow Obfuscation:** Adds fake control flow structures to confuse static analysis.
- **Garbage Code Insertion:** Injects junk code to bloat and obscure the script.
- **Bytecode Encoding:** Converts parts of a script into bytecode, making them harder to follow.
- **Function Inlining:** Integrates function code directly into calls, obscuring the original structure and logic.
- **Opaque Predicates:** Uses complex conditions that always evaluate to true or false, obscuring actual purpose.
- **Dynamic Code Generator:** Generates code blocks from the script itself, to complicate static analysis.

>[!TIP]
>You can customize your level of obfuscation through the `config.lua` file.
---
## Installation

### macOS and Linux

1. Clone this repository:
    ```bash
    git clone https://github.com/zeusssz/hercules-obfuscator.git
    cd hercules-obfuscator/src
    ```

2. Make the `hercules` script executable:
    ```bash
    chmod +x hercules
    ```

3. Run the obfuscator:
    ```bash
    ./hercules path/to/your/script.lua
    ```
>[!NOTE]
>Ensure you are in the working directory of the executable, i.e., `src` by default. Alternatively, you can use the Lua interpreter directly if it is added to your system PATH.

### Windows

1. Clone this repository using Git Bash or download the ZIP file and extract it.

2. Open Command Prompt or PowerShell and navigate to the `hercules-obfuscator` directory.

3. Run the obfuscator using Lua:
    ```cmd
    lua src\hercules path\to\your\script.lua
    ```
---

## Usage

To obfuscate a Lua script using Hercules, simply run:

```bash
./hercules path/to/your/script.lua  # macOS/Linux
lua src\hercules path\to\your\script.lua  # Windows
```

This will generate an obfuscated version of the script in the same directory, with the filename `*_obfuscated.lua`.

## Example

```bash
./hercules my_script.lua  # macOS/Linux
lua src\hercules my_script.lua  # Windows
```

Output:
`my_script_obfuscated.lua` – the obfuscated version of your script.
<br>
<br>

---
Original Script : `file.lua`
```lua
-- Function to print a greeting message
function Greet(name)
    print("Hello, " .. name .. "!")
end

-- Function to add two numbers
function Add(a, b)
    return a + b
end

-- Function to test a basic conditional statement
function CheckNumber(num)
    if num > 0 then
        print(num .. " is positive.")
    elseif num < 0 then
        print(num .. " is negative.")
    else
        print(num .. " is zero.")
    end
end

Greet("You")

local sum = Add(5, 10)
print("The sum of 5 and 10 is: " .. sum)

CheckNumber(5)   -- Output: 5 is positive.
CheckNumber(-3)  -- Output: -3 is negative.
CheckNumber(0)   -- Output: 0 is zero.
```
<br>

Obfuscated Script : `file_obfuscated.lua` (except Function Inliner & Dynamic Code Generator)
```lua
--[Obfuscated by Hercules v1.5 | discord.gg/Hx6RuYs8Ku]
local function tyymrm(lplljv) local function ododkg(irubjz) local wimnwd = 67 end end local vndskt = 16 local function jsxbai(wpzksz) local jurvpy = 70 end local executed = false while not executed do if math.random(0, 1) == 0 then local _ = 250 else executed = true end end local function pAPkMUmMJgG(byte) return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) end local function BTeAOpsBVUB(code, offset) local result = {} for i = 1, #code do local byte = code:byte(i) if pAPkMUmMJgG(byte) then local new_byte if byte >= 48 and byte <= 57 then new_byte = ((byte - 48 - offset + 10) % 10) + 48 elseif byte >= 65 and byte <= 90 then new_byte = ((byte - 65 - offset + 26) % 26) + 65 elseif byte >= 97 and byte <= 122 then new_byte = ((byte - 97 - offset + 26) % 26) + 97 end table.insert(result, string.char(new_byte)) else table.insert(result, string.char(byte)) end end return table.concat(result) end local function pAPkMUmMJgG(byte) return (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) end function ytYDTgbo(vzWhayfj) print(BTeAOpsBVUB("Yvccf, ", 17) .. vzWhayfj .. BTeAOpsBVUB("!", 4)) end function YxLYRxiEgb(muCLPSUXq, HMFyWCWQOe) return muCLPSUXq + HMFyWCWQOe end function uAHwInWiT(PcvxKPZzxCMI) if PcvxKPZzxCMI > 0 then print(PcvxKPZzxCMI .. BTeAOpsBVUB(" xh edhxixkt.", 15)) elseif PcvxKPZzxCMI < 0 then print(PcvxKPZzxCMI .. BTeAOpsBVUB(" rb wnpjcren.", 9)) else print(PcvxKPZzxCMI .. BTeAOpsBVUB(" td kpcz.", 11)) end end ytYDTgbo(BTeAOpsBVUB("Oek", 16)) local RRzpmwUHCbzC = YxLYRxiEgb(5, 10) print(BTeAOpsBVUB("Ocz nph ja 6 viy 21 dn: ", 21) .. RRzpmwUHCbzC) uAHwInWiT(5) uAHwInWiT(-3) uAHwInWiT(0)
```
---

If you specify the overwrite option with the `--overwrite` flag, it will write back to the specified script.
<br>
You may also specify an alternate pipeline file using `--pipeline`, along with a file argument. For example:
```sh
lua src\hercules.lua my_script.lua --pipeline custom_pipeline.lua 
```
>[!NOTE]
>Ensure that your custom pipeline file is **in the same directory** as `hercules.lua`.

## Customization

You can modify or add new modules to the `modules/` directory to create additional layers of obfuscation. The `pipeline.lua` file controls the order of obfuscation steps.

---

## Project Structure

```
src/
│
├── hercules            # Main entry point (executable)
├── pipeline.lua        # Obfuscation pipeline
└── modules/            # Obfuscation modules  
```
>[!IMPORTANT]
>When adding more modules to the `modules/` directory, ensure you maintain the integrity of the executable, and remember to add your module to the `pipeline.lua` file.
<br>If you wish for it to be configurable, add it to the `config.lua` file, along with the necessary logic.

## Incoming Updates
GUI Update
Fixes of unreliable modules

![herculessmall](https://github.com/user-attachments/assets/ff2ed207-c95e-45c3-831f-04a32675dbb5?size=32) 
# Hercules Lua Obfuscator
![Stars](https://img.shields.io/github/stars/zeusssz/hercules-obfuscator?style=flat-square)
![Forks](https://img.shields.io/github/forks/zeusssz/hercules-obfuscator?style=flat-square)
![Issues](https://img.shields.io/github/issues/zeusssz/hercules-obfuscator?style=flat-square)
![License](https://img.shields.io/github/license/zeusssz/hercules-obfuscator?style=flat-square)
![Last Commit](https://img.shields.io/github/last-commit/zeusssz/hercules-obfuscator?style=flat-square)
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

- **String Encoding:** Obfuscates strings by encoding them in base64 with additional scrambling.
- **Variable Renaming:** Replaces variable names with randomly generated names.
- **Control Flow Obfuscation:** Adds fake control flow structures to confuse static analysis.
- **Garbage Code Insertion:** Injects junk code to bloat and obscure the script.
- **Watermarking:** Automatically appends a watermark to indicate that the code has been obfuscated by Hercules.

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

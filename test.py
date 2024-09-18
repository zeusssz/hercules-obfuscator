import itertools
import os
import subprocess
import shutil

# Define the factorial test Lua code
factorial_test_code = '''function factorial(n)
    if n == 0 then
        return 1
    else
        return n * factorial(n - 1)
    end
end

local result = factorial(13)
print(result)
'''

# List of modules with full names (no abbreviations in this part)
modules = [
    ("StringEncoder", "modules/string_encoder"),
    ("VariableRenamer", "modules/variable_renamer"),
    ("ControlFlowObfuscator", "modules/control_flow_obfuscator"),
    ("GarbageCodeInserter", "modules/garbage_code_inserter"),
    ("OpaquePredicateInjector", "modules/opaque_predicate_injector"),
    ("FunctionInliner", "modules/function_inliner"),
    ("DynamicCodeGenerator", "modules/dynamic_code_generator"),
    ("BytecodeEncoder", "modules/bytecode_encoder"),
    ("Watermarker", "modules/watermark")
]

# Define abbreviations for the legend
module_abbreviations = {
    "StringEncoder": "SE",
    "VariableRenamer": "VR",
    "ControlFlowObfuscator": "CFO",
    "GarbageCodeInserter": "GCI",
    "OpaquePredicateInjector": "OPI",
    "FunctionInliner": "FI",
    "DynamicCodeGenerator": "DCG",
    "BytecodeEncoder": "BCE",
    "Watermarker": "WM"
}

# Change the current working directory to the src directory
os.chdir('./src')

# Save path to lua5.1 binary
LUA = shutil.which('lua54')
if LUA is None:
    LUA = shutil.which('lua5.4')
    if LUA is None:
        print("Lua 5.4 not found. Please install Lua 5.4 and try again.")
        # If OS is apt based, suggest installing Lua 5.4
        if shutil.which('apt-get') is not None:
            print("Do you want to install Lua 5.4? (y/n)")
            response = input()
            if response.lower() == 'y':
                subprocess.run(['sudo', 'apt-get', 'install', 'lua5.4'])
                print("Lua 5.4 installed. Please run the script again.")
                exit(0)
            else:
                print("Please install Lua 5.4 and run the script again.")
                exit(1)
        else:
            print("Please install Lua 5.4 and run the script again.")
            exit(1)

# Create the factorial test Lua file (testfile.lua)
test_file_path = './testfile.lua'
with open(test_file_path, 'w') as f:
    f.write(factorial_test_code)

# Load the original pipeline.lua content
pipeline_path = './pipeline.lua'
with open(pipeline_path, 'r') as f:
    original_pipeline_content = f.read()

# Function to comment out modules in the 'require' and 'process' sections
def modify_pipeline(content, active_modules):
    modified_content = content
    
    # Comment out unused modules in the 'require' section
    for module_name, module_path in modules:
        if module_name not in active_modules:
            modified_content = modified_content.replace(f'local {module_name} = require("{module_path}")', f'-- local {module_name} = require("{module_path}")')
    
    # Comment out unused modules in the 'process' section
    for module_name, _ in modules:
        if module_name not in active_modules:
            modified_content = modified_content.replace(f'code = {module_name}.process(code)', f'-- code = {module_name}.process(code)')
    
    return modified_content

# Function to run the pipeline and check output
def run_pipeline(combination):
    # Modify the pipeline.lua content for this combination
    modified_pipeline = modify_pipeline(original_pipeline_content, combination)
    
    # Backup the original pipeline.lua
    shutil.copyfile(pipeline_path, pipeline_path + '.bak')
    
    # Write the modified pipeline.lua
    with open(pipeline_path, 'w') as f:
        f.write(modified_pipeline)

    # Run hercules.lua with the testfile.lua and capture output
    try:
        subprocess.run([LUA, './hercules.lua', './testfile.lua'])

        # Run the obfuscated testfile and capture output
        result = subprocess.run([LUA, './testfile_obfuscated.lua'], capture_output=True, text=True, timeout=5)
        
        # Check if the result is correct
        test_passed = '6227020800' in result.stdout
        return test_passed, False  # False indicates no timeout

    except subprocess.TimeoutExpired:
        return False, True  # True indicates a timeout

    finally:
        # Restore the original pipeline.lua
        shutil.move(pipeline_path + '.bak', pipeline_path)

# Run tests and store results
test_results = []
total_tests = 0
passed_tests = 0
timeout_tests = 0
failed_combinations = []
timeout_combinations = []
success_combinations = []

# Sanitycheck with all modules commented out
sanitycheck_passed, sanitycheck_timeout = run_pipeline([])
test_results.append({
    "Combination": "Sanitycheck (no modules active)",
    "Result": "Passed" if sanitycheck_passed else ("Timeout" if sanitycheck_timeout else "Failed")
})
total_tests += 1
if sanitycheck_passed:
    passed_tests += 1
    success_combinations.append("Sanitycheck")
elif sanitycheck_timeout:
    timeout_tests += 1
    timeout_combinations.append("Sanitycheck")
else:
    failed_combinations.append("Sanitycheck")

# Create combinations of modules
for i in range(1, len(modules) + 1):
    for combination in itertools.combinations([module[0] for module in modules], i):
        test_passed, test_timeout = run_pipeline(combination)
        test_results.append({
            "Combination": ', '.join(combination),
            "Result": "Passed" if test_passed else ("Timeout" if test_timeout else "Failed")
        })
        total_tests += 1
        if test_passed:
            passed_tests += 1
            success_combinations.append(', '.join(combination))
        elif test_timeout:
            timeout_tests += 1
            timeout_combinations.append(', '.join(combination))
        else:
            failed_combinations.append(', '.join(combination))

# Calculate pass percentage
pass_percentage = (passed_tests / total_tests) * 100

# Write results to text file with legend
result_file_path = './test_results.txt'
with open(result_file_path, 'w') as f:
    # Write legend
    f.write("Legend:\n")
    for module_name, abbreviation in module_abbreviations.items():
        f.write(f"{abbreviation}: {module_name}\n")
    f.write("\n")
    
    # Write test results with correct padding
    if failed_combinations or timeout_combinations or success_combinations:
        f.write("Test Results:\n")
        for combination in success_combinations:
            if combination == "Sanitycheck":
                abbreviated_combination = combination
            else:
                abbreviated_combination = ', '.join([module_abbreviations[module] for module in combination.split(', ')])
            f.write(f"[SUCCESS] ---- {abbreviated_combination.ljust(40)}\n")
        for combination in failed_combinations:
            if combination == "Sanitycheck":
                abbreviated_combination = combination
            else:
                abbreviated_combination = ', '.join([module_abbreviations[module] for module in combination.split(', ')])
            f.write(f"[FAIL] ------- {abbreviated_combination.ljust(40)}\n")
        for combination in timeout_combinations:
            if combination == "Sanitycheck":
                abbreviated_combination = combination
            else:
                abbreviated_combination = ', '.join([module_abbreviations[module] for module in combination.split(', ')])
            f.write(f"[TIMEOUT] - {abbreviated_combination.ljust(40)}\n")
    else:
        f.write("All tests passed!\n")
    
    # Write summary
    f.write(f"\nSummary: {passed_tests}/{total_tests} passed ({pass_percentage:.2f}%)\n")
    f.write(f"Timeouts: {timeout_tests}/{total_tests}\n")

# Cleanup
os.remove("testfile.lua")
os.remove("testfile_obfuscated.lua")

# Display summary in terminal
print(f"Summary: {passed_tests}/{total_tests} passed ({pass_percentage:.2f}%)")
print(f"Timeouts: {timeout_tests}/{total_tests}")
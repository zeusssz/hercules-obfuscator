import itertools
import os
import subprocess
import sys
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
GMOD_DIR = Path("/opt/gmod/garrysmod/data/hercules_tests")
GMOD_EXE = Path("/opt/gmod/srcds_run")
GMOD_LOG = Path("/tmp/hercules-gmod.log")

HTTP_TIMEOUT = 30
GMOD_STARTUP_TIMEOUT = 180
GMOD_FILE_TIMEOUT = 20
GMOD_POLL_INTERVAL = 0.05
NUM_WORKERS = int(os.getenv("HERCULES_TEST_WORKERS", "16"))

METHODS = {
    "antitamper": "--antitamper",
    "control_flow": "--control_flow",
    "string_to_expressions": "--string_to_expressions",
    "string_encoding": "--string_encoding",
    "wrap_in_function": "--wrap_in_function",
    "variable_renaming": "--variable_renaming",
    "garbage_code": "--garbage_code",
    "opaque_predicates": "--opaque_predicates",
    "function_inlining": "--function_inlining",
    "dynamic_code": "--dynamic_code",
    "compressor": "--compressor",
    "virtual_machine": "--virtual_machine",
    "bytecode_encoding": "--bytecode_encoding",
}

COMMON_METHODS = [
    "antitamper",
    "control_flow",
    "string_to_expressions",
    "string_encoding",
    "wrap_in_function",
    "variable_renaming",
    "garbage_code",
    "opaque_predicates",
    "function_inlining",
    "dynamic_code",
    "compressor",
]

LANGUAGES = {
    "lua": {
        "input": 'print("lua-ok")',
        "expected": "lua-ok",
        "methods": COMMON_METHODS + ["virtual_machine", "bytecode_encoding"],
        "suffix": ".lua",
    },
    "luau": {
        "input": 'local label: string = "luau-ok"\nprint(label)',
        "expected": "luau-ok",
        "methods": COMMON_METHODS,
        "suffix": ".luau",
    },
    "glua": {
        "input": 'local v = Vector(1, 2, 3)\nprint("glua-ok")',
        "expected": "glua-ok",
        "methods": COMMON_METHODS,
        "suffix": ".lua",
    },
}

failures = []
failures_lock = threading.Lock()
gmod_proc = None


def main():
    global gmod_proc

    gmod_proc = start_gmod()
    print("GMod ready")

    for lang_name, lang_config in LANGUAGES.items():
        run_language(lang_name, lang_config)

    stop_gmod()

    if failures:
        print(f"\n{'=' * 60}")
        print(f"FAILURES: {len(failures)}")
        print(f"{'=' * 60}")
        for lang, cid, combo, msg in failures:
            print(f"  [{lang}] combo #{cid} {list(combo)}")
            print(f"    {msg}")
            print()
        sys.exit(1)

    print(f"\n{'=' * 60}")
    print("ALL COMBINATIONS PASSED")
    print(f"{'=' * 60}")


def start_gmod():
    if not GMOD_EXE.exists():
        print("ERROR: GMod runtime is required for GLua verification")
        sys.exit(1)

    GMOD_DIR.mkdir(parents=True, exist_ok=True)
    for old_file in GMOD_DIR.glob("*"):
        old_file.unlink()
    GMOD_LOG.unlink(missing_ok=True)

    log = GMOD_LOG.open("w", encoding="utf-8")
    proc = subprocess.Popen(
        [
            str(GMOD_EXE),
            "-console",
            "-game",
            "garrysmod",
            "+map",
            "gm_construct",
            "+sv_allowcslua",
            "1",
            "-disableluarefresh",
        ],
        stdout=log,
        stderr=subprocess.STDOUT,
    )

    ready_file = GMOD_DIR / "ready.txt"
    start = time.time()
    while time.time() - start < GMOD_STARTUP_TIMEOUT:
        if ready_file.exists():
            ready_file.unlink()
            return proc
        if proc.poll() is not None:
            print("ERROR: GMod exited before becoming ready")
            print_gmod_log_tail()
            sys.exit(1)
        time.sleep(0.5)

    proc.terminate()
    print("ERROR: GMod did not become ready")
    print_gmod_log_tail()
    sys.exit(1)


def stop_gmod():
    if gmod_proc is not None and gmod_proc.poll() is None:
        print("Shutting down GMod...")
        gmod_proc.terminate()
        try:
            gmod_proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            gmod_proc.kill()


def run_language(lang_name, lang_config):
    methods = lang_config["methods"]
    total = 2 ** len(methods) - 1
    print(f"\n  {lang_name}: {total} combos ({len(methods)} methods)")

    combos = []
    combo_ids = []
    combo_id = 0
    for size in range(1, len(methods) + 1):
        for combo in itertools.combinations(methods, size):
            combo_id += 1
            combos.append(combo)
            combo_ids.append(combo_id)

    done = 0
    with ThreadPoolExecutor(max_workers=NUM_WORKERS) as pool:
        futures = {
            pool.submit(run_combo, lang_name, lang_config, cid, combo): cid
            for cid, combo in zip(combo_ids, combos)
        }
        for future in as_completed(futures):
            done += 1
            if done % 500 == 0 or done == total:
                print(f"    {lang_name}: {done}/{total} combos done", flush=True)
            future.result()

    print(f"    {lang_name}: {done}/{total} complete")


def run_combo(lang_name, lang_config, combo_id, combo):
    ok, result = obfuscate(lang_name, lang_config, combo)
    if not ok:
        add_failure(lang_name, combo_id, combo, result)
        return

    ok, msg = validate_output(lang_name, result, lang_config["expected"], combo_id)
    if not ok:
        add_failure(lang_name, combo_id, combo, msg)


def obfuscate(lang_name, lang_config, combo):
    suffix = lang_config["suffix"]
    with tempfile.NamedTemporaryFile(
        suffix=suffix, delete=False, mode="w", encoding="utf-8"
    ) as handle:
        handle.write(lang_config["input"])
        path = Path(handle.name)

    command = ["lua5.4", "hercules.lua", str(path), "--target", lang_name]
    command.extend(METHODS[m] for m in combo)
    command.append("--overwrite")

    try:
        result = subprocess.run(
            command,
            cwd=SRC,
            capture_output=True,
            text=True,
            timeout=HTTP_TIMEOUT,
        )
        if result.returncode != 0:
            return False, (result.stdout + result.stderr)[:500]
        return True, path.read_text(encoding="utf-8")
    except subprocess.TimeoutExpired:
        return False, "obfuscation timed out"
    finally:
        path.unlink(missing_ok=True)


def validate_output(lang_name, code, expected, combo_id):
    if lang_name == "lua":
        return validate_lua(code, expected)
    if lang_name == "luau":
        return validate_luau(code, expected)
    if lang_name == "glua":
        return validate_glua(code, expected, combo_id)
    return False, f"unknown language: {lang_name}"


def validate_lua(code, expected):
    with temp_code_file(".lua", code) as path:
        check = subprocess.run(
            ["luacheck", str(path)], capture_output=True, text=True, timeout=10
        )
        if check.returncode not in (0, 1):
            return False, (check.stdout + check.stderr)[:500]

        run = subprocess.run(
            ["lua5.4", str(path)], capture_output=True, text=True, timeout=10
        )
        if run.returncode != 0:
            return False, (run.stdout + run.stderr)[:500]
        return output_matches(run.stdout, expected)


def validate_luau(code, expected):
    with temp_code_file(".luau", code) as path:
        analyze = subprocess.run(
            ["luau-analyze", str(path)], capture_output=True, text=True, timeout=10
        )
        if "SyntaxError" in analyze.stdout + analyze.stderr:
            return False, (analyze.stdout + analyze.stderr)[:500]

        run = subprocess.run(
            ["luau", str(path)], capture_output=True, text=True, timeout=10
        )
        if run.returncode != 0:
            return False, (run.stdout + run.stderr)[:500]
        return output_matches(run.stdout, expected)


def validate_glua(code, expected, combo_id):
    with temp_code_file(".lua", code) as path:
        lint = subprocess.run(
            ["glualint", str(path)], capture_output=True, text=True, timeout=10
        )
        if lint.returncode not in (0, 1):
            return False, (lint.stdout + lint.stderr)[:500]

    lua_file = GMOD_DIR / f"c{combo_id}.lua"
    result_file = GMOD_DIR / f"c{combo_id}.lua.result.txt"
    staging_file = GMOD_DIR / f"c{combo_id}.staging.txt"
    lua_file.unlink(missing_ok=True)
    result_file.unlink(missing_ok=True)
    staging_file.write_text(code, encoding="utf-8")
    staging_file.replace(lua_file)

    start = time.time()
    while time.time() - start < GMOD_FILE_TIMEOUT:
        if result_file.exists():
            result = result_file.read_text(encoding="utf-8", errors="replace").strip()
            result_file.unlink()
            if result.startswith("PASS:"):
                return output_matches(result[5:], expected)
            return False, result[:500]
        time.sleep(GMOD_POLL_INTERVAL)

    return False, "TIMEOUT: GMod did not process file"


class temp_code_file:
    def __init__(self, suffix, code):
        self.suffix = suffix
        self.code = code
        self.path = None

    def __enter__(self):
        handle = tempfile.NamedTemporaryFile(
            suffix=self.suffix, delete=False, mode="w", encoding="utf-8"
        )
        with handle:
            handle.write(self.code)
        self.path = Path(handle.name)
        return self.path

    def __exit__(self, *_args):
        if self.path is not None:
            self.path.unlink(missing_ok=True)


def output_matches(actual, expected):
    lines = [line.strip() for line in actual.splitlines() if line.strip()]
    if expected in lines:
        return True, ""
    return False, f"expected output {expected!r}, got {actual[:500]!r}"


def add_failure(lang_name, combo_id, combo, msg):
    with failures_lock:
        failures.append((lang_name, combo_id, combo, msg))


def print_gmod_log_tail():
    if not GMOD_LOG.exists():
        print("GMod log was not created")
        return
    lines = GMOD_LOG.read_text(errors="replace").splitlines()
    print("\n".join(lines[-80:]))


if __name__ == "__main__":
    main()

import math
import os
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

# 14 manifest modules plus synthetic watermark bit.
TOTAL_MASKS = 2**15 - 1
MODULES = [
    "VirtualMachine",
    "antitamper",
    "control_flow",
    "StringToExpressions",
    "string_encoding",
    "WrapInFunction",
    "variable_renaming",
    "garbage_code",
    "opaque_predicates",
    "function_inlining",
    "dynamic_code",
    "bytecode_encoding",
    "compressor",
    "constant_encoding",
    "watermark",
]


def main():
    if len(sys.argv) != 2:
        print("usage: fixture_sweep_parallel.py <fixture>", file=sys.stderr)
        return 2

    fixture = sys.argv[1]
    workers = max(1, int(os.getenv("HERCULES_LUA_TEST_WORKERS", str(os.cpu_count() or 1))))
    chunk_size = max(1, int(os.getenv("HERCULES_LUA_TEST_CHUNK_SIZE", "16")))
    lua_bin = os.getenv("LUA_BIN") or shutil.which("lua5.4") or "lua"
    total_masks = min(TOTAL_MASKS, max(1, int(os.getenv("HERCULES_LUA_TEST_MAX_MASK", str(TOTAL_MASKS)))))

    chunks = list(make_chunks(chunk_size, total_masks))
    done = 0
    passed = 0
    failures = []
    started = time.monotonic()
    next_progress = min(500, total_masks)

    print(
        f"  {fixture}: {total_masks} combos, {workers} workers, chunk size {chunk_size}",
        flush=True,
    )

    with tempfile.TemporaryDirectory(prefix="hercules-fixture-sweep-") as tmp:
        tmpdir = Path(tmp)
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [
                pool.submit(run_chunk, lua_bin, fixture, start, end, tmpdir / f"{start}-{end}.txt")
                for start, end in chunks
            ]
            for future in as_completed(futures):
                start, end, chunk_pass, chunk_failures = future.result()
                chunk_total = end - start + 1
                done += chunk_total
                passed += chunk_pass
                failures.extend(chunk_failures)

                if done >= next_progress or done == total_masks:
                    print_progress(fixture, done, started, total_masks)
                    while next_progress <= done:
                        next_progress += 500

    elapsed = time.monotonic() - started
    rate = done / elapsed if elapsed > 0 else 0
    print(f"\r  {fixture}: {done}/{total_masks} combos done (100.0%, {rate:.0f} combos/s, {elapsed:.1f}s)")
    print(f"  {fixture}: {passed}/{total_masks} combos pass")

    if failures:
        print(f"  {fixture}: {len(failures)} combinations failed")
        for mask, reason, detail in failures[:50]:
            print(f"    [{mask_to_label(mask)}] {reason}: {detail}")
        if len(failures) > 50:
            print(f"    ... and {len(failures) - 50} more")
        return 1

    return 0


def make_chunks(chunk_size, total_masks):
    start = 1
    while start <= total_masks:
        end = min(total_masks, start + chunk_size - 1)
        yield start, end
        start = end + 1


def run_chunk(lua_bin, fixture, start, end, result_path):
    command = [
        lua_bin,
        "tests/fixture_sweep_worker.lua",
        fixture,
        str(start),
        str(end),
        str(result_path),
    ]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=600)
    if result.returncode != 0:
        output = (result.stdout + result.stderr).strip()[:500]
        return start, end, 0, [(start, "worker failed", output)]

    return parse_result(result_path, start, end)


def parse_result(path, start, end):
    passed = 0
    failures = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        fields = line.split("\t", 2)
        if len(fields) < 2:
            continue
        if fields[0] == "pass":
            passed = int(fields[1])
        elif fields[0] == "fail":
            continue
        elif fields[0].isdigit():
            mask = int(fields[0])
            reason = fields[1]
            detail = fields[2] if len(fields) > 2 else ""
            failures.append((mask, reason, detail))
        else:
            failures.append((start, "worker result parse error", line[:250]))

    if passed + len(failures) != end - start + 1:
        failures.append((start, "worker result mismatch", f"{passed} pass, {len(failures)} fail"))

    return start, end, passed, failures


def print_progress(fixture, done, started, total_masks):
    elapsed = time.monotonic() - started
    rate = done / elapsed if elapsed > 0 else 0
    remaining = total_masks - done
    eta = remaining / rate if rate > 0 else math.inf
    pct = (done / total_masks) * 100
    print(
        f"\r  {fixture}: {done}/{total_masks} combos done "
        f"({pct:.1f}%, {rate:.0f} combos/s, ETA: {format_eta(eta)}) ",
        end="",
        flush=True,
    )


def format_eta(seconds):
    if math.isinf(seconds):
        return "unknown"
    if seconds < 60:
        return f"{math.ceil(seconds)}s"
    if seconds < 3600:
        return f"{int(seconds // 60)}m {math.ceil(seconds % 60)}s"
    return f"{int(seconds // 3600)}h {int((seconds % 3600) // 60)}m"


def mask_to_label(mask):
    return "+".join(module for index, module in enumerate(MODULES) if mask & (1 << index))


if __name__ == "__main__":
    raise SystemExit(main())

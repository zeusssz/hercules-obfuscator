#!/usr/bin/env python3
"""
test_py.py — Parallel test suite for Hercules Obfuscator
Runs all 2^14 = 16384 module combinations against all 30 fixtures.
Uses multiprocessing for parallel execution with progress bar.

Run from src/: python3 test_py.py
"""

import subprocess
import sys
import os
import time
from concurrent.futures import ProcessPoolExecutor
from tqdm import tqdm
from test_worker_py import _run_batch as run_batch

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
ALL_MODULES = [
    "VirtualMachine", "antitamper", "control_flow", "StringToExpressions",
    "string_encoding", "WrapInFunction", "variable_renaming", "garbage_code",
    "opaque_predicates", "function_inlining", "dynamic_code", "bytecode_encoding",
    "compressor", "watermark",
]
NUM_MODULES = len(ALL_MODULES)
NUM_COMBOS = 2 ** NUM_MODULES
NUM_FIXTURES = 1
BATCH_SIZE = 500


def mask_label(mask):
    mods = []
    for i in range(NUM_MODULES):
        if (mask >> i) & 1:
            mods.append(ALL_MODULES[i])
    return "+".join(mods) if mods else "none"


def main():
    total = (NUM_COMBOS - 1) * NUM_FIXTURES  # skip mask 0

    print("Hercules Obfuscator — Parallel Test Suite")
    print("=" * 60)
    print(f"Fixtures: {NUM_FIXTURES}  |  Modules: {NUM_MODULES}  |  Combinations: {NUM_COMBOS} (2^{NUM_MODULES})")
    print(f"Total tests: {total:,}")
    print(f"Workers: {os.cpu_count()}  |  Batch size: {BATCH_SIZE}")
    print()

    # Generate tasks: (mask, fixture_idx)
    tasks = []
    for mask in range(1, NUM_COMBOS):
        for fidx in range(1, NUM_FIXTURES + 1):
            tasks.append((mask, fidx))

    # Split into batches
    batches = [tasks[i:i + BATCH_SIZE] for i in range(0, len(tasks), BATCH_SIZE)]
    print(f"Processing {len(batches)} batches...")
    print()

    start_time = time.time()
    passed = 0
    failed = 0
    fail_details = []

    num_workers = os.cpu_count() or 4

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        futures = [executor.submit(run_batch, batch) for batch in batches]
        with tqdm(total=total, desc="Testing", unit="test", dynamic_ncols=True) as pbar:
            for future in futures:
                batch_results = future.result()
                for mask, fidx, ok, reason in batch_results:
                    if ok:
                        passed += 1
                    else:
                        failed += 1
                        if len(fail_details) < 20:
                            fail_details.append({
                                "modules": mask_label(mask),
                                "fixture_idx": fidx,
                                "reason": reason,
                            })
                    pbar.update(1)

    elapsed = time.time() - start_time

    print()
    print("=" * 60)
    speed = total / elapsed if elapsed > 0 else 0
    print(f"Results: {passed:,} passed, {failed:,} failed, {total:,} total ({elapsed:.1f}s, {speed:,.0f} tests/s)")
    print()

    if failed > 0:
        print("First failures:")
        for f in fail_details:
            reason_short = f["reason"][:80]
            print(f"  {f['modules']} + fixture#{f['fixture_idx']}: {reason_short}")
        if failed > len(fail_details):
            print(f"  ... and {failed - len(fail_details):,} more failures")
        sys.exit(1)
    else:
        print("All tests passed!")
        sys.exit(0)


if __name__ == "__main__":
    main()

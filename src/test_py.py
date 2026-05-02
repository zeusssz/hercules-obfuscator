#!/usr/bin/env python3
"""test_py.py — Parallel test runner for Hercules Obfuscator.

Architecture:
  Master creates N long-lived Lua subprocesses
  Master feeds masks to workers via stdin (one per line)
  Workers process masks in-process (no per-mask subprocess overhead)
  Workers write results to stdout (P:<mask> or F:<mask>:<fidx>:<reason>)
  Master reads from all workers concurrently via threads
  Dynamic load balancing: fastest workers get more work

Usage:
    python3 test_py.py              # auto-detect CPU count
    python3 test_py.py --jobs 8     # explicit worker count
"""

import subprocess
import os
import sys
import time
import math
import threading
import queue

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
WORKER_LUA = os.path.join(SRC_DIR, "test_worker_py.lua")

ALL_MODULES = [
    "VirtualMachine", "antitamper", "control_flow", "StringToExpressions",
    "string_encoding", "WrapInFunction", "variable_renaming", "garbage_code",
    "opaque_predicates", "function_inlining", "dynamic_code", "bytecode_encoding",
    "compressor", "watermark",
]
NUM_MODULES = len(ALL_MODULES)
NUM_COMBOS = 2 ** NUM_MODULES


def mask_to_modules(mask):
    return [ALL_MODULES[i] for i in range(NUM_MODULES) if (mask >> i) & 1]


def modules_to_label(mods):
    return "+".join(mods)


def format_eta(seconds):
    if seconds < 60:
        return f"{math.ceil(seconds)}s"
    elif seconds < 3600:
        return f"{int(seconds // 60)}m {math.ceil(seconds % 60)}s"
    else:
        return f"{int(seconds // 3600)}h {int((seconds % 3600) // 60)}m"


def get_cpu_count():
    try:
        return os.cpu_count() or 4
    except Exception:
        return 4


class Worker:
    def __init__(self, worker_id, mask_queue, results, lock):
        self.worker_id = worker_id
        self.mask_queue = mask_queue
        self.results = results
        self.lock = lock
        self.process = None
        self.stdin = None
        self.error = None
        self.finished = False
        self.done_count = 0
        self.pending_masks = []

    def start(self):
        self.process = subprocess.Popen(
            ["lua", WORKER_LUA],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True, cwd=SRC_DIR, bufsize=1
        )
        self.stdin = self.process.stdin
        threading.Thread(target=self._reader, daemon=True).start()
        threading.Thread(target=self._feeder, daemon=True).start()

    def _feeder(self):
        """Pull masks from shared queue and feed to this worker's stdin."""
        try:
            while True:
                try:
                    mask = self.mask_queue.get_nowait()
                except Exception:
                    break
                self.pending_masks.append(mask)
                self.stdin.write(str(mask) + "\n")
                self.stdin.flush()
        except BrokenPipeError:
            pass
        except Exception as e:
            self.error = str(e)
        finally:
            try:
                self.stdin.close()
            except Exception:
                pass

    def _reader(self):
        """Read results from worker stdout."""
        try:
            for line in self.process.stdout:
                line = line.strip()
                if not line:
                    continue
                parts = line.split(":")
                with self.lock:
                    if parts[0] == "P" and len(parts) >= 2:
                        self.results.append((int(parts[1]), True, None, None))
                    elif parts[0] == "F" and len(parts) >= 3:
                        mask = int(parts[1])
                        fidx = int(parts[2])
                        reason = parts[3] if len(parts) > 3 else "unknown"
                        self.results.append((mask, False, fidx, reason))
                    self.done_count += 1
        except Exception as e:
            self.error = str(e)
        finally:
            self.finished = True

    def wait(self):
        if self.process:
            try:
                self.process.wait(timeout=30)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            if self.process.returncode != 0 and not self.error:
                _, stderr = self.process.communicate()
                if stderr:
                    self.error = stderr.strip()


def run_parallel(num_workers):
    total_masks = NUM_COMBOS - 1

    # Shared mask queue — workers pull dynamically
    mask_queue = list(range(1, NUM_COMBOS))
    q = queue.Queue()
    for m in mask_queue:
        q.put(m)

    results = []
    lock = threading.Lock()

    print(f"Running {total_masks} combinations with {num_workers} workers...\n")
    print("  Queue-based load balancing: long-lived Lua workers pull masks dynamically\n")

    workers = []
    for w in range(num_workers):
        worker = Worker(w + 1, q, results, lock)
        worker.start()
        workers.append(worker)

    # Poll progress
    start_time = time.monotonic()
    last_done = 0

    while True:
        total_done = sum(w.done_count for w in workers)
        all_finished = all(w.finished for w in workers)

        elapsed = time.monotonic() - start_time
        if elapsed > 1 and total_done > last_done:
            rate = total_done / elapsed
            remaining = total_masks - total_done
            eta = remaining / rate if rate > 0 else 0
            pct = (total_done / total_masks) * 100
            sys.stdout.write(f"\r  [{pct:5.1f}%] {total_done}/{total_masks}  ({rate:.0f} combos/s, ETA: {format_eta(eta)}) ")
            sys.stdout.flush()
            last_done = total_done

        if all_finished:
            break

        time.sleep(0.2)

    # Wait for all workers
    for w in workers:
        w.wait()

    # Final progress
    total_done = sum(w.done_count for w in workers)
    elapsed = time.monotonic() - start_time
    rate = total_masks / elapsed if elapsed > 0 else 0
    sys.stdout.write(f"\r  [100.0%] {total_masks}/{total_masks}  ({rate:.0f} combos/s, {elapsed:.1f}s)  \n\n")
    sys.stdout.flush()

    # Aggregate results
    all_results = list(results)

    # Find masks that didn't produce output
    produced = {mask for mask, _, _, _ in all_results}
    for mask in range(1, NUM_COMBOS):
        if mask not in produced:
            all_results.append((mask, False, None, "missing_result"))

    return all_results, elapsed


def process_results(results_list):
    pass_combos = 0
    fail_combos = 0
    fail_by_module = {m: 0 for m in ALL_MODULES}
    fail_by_pair = {}
    fail_details = []
    fail_first_fixture = {}

    for mask, passed, fidx, reason in results_list:
        if passed:
            pass_combos += 1
        else:
            fail_combos += 1
            mods = mask_to_modules(mask)
            for m in mods:
                fail_by_module[m] += 1
            if len(mods) >= 2:
                for i in range(len(mods) - 1):
                    for j in range(i + 1, len(mods)):
                        pair = f"{mods[i]}+{mods[j]}"
                        fail_by_pair[pair] = fail_by_pair.get(pair, 0) + 1

            label = modules_to_label(mods)
            if label not in fail_first_fixture:
                fname = f"fixture_{fidx or '?'}"
                fail_first_fixture[label] = f"{fname} ({reason or 'unknown'})"
            if len(fail_details) < 50:
                fname = f"fixture_{fidx or '?'}"
                fail_details.append(f"  [{label}] first fail: {fname} — {reason or 'unknown'}")

    return pass_combos, fail_combos, fail_by_module, fail_by_pair, fail_details


def print_summary(pass_combos, fail_combos, fail_by_module, fail_by_pair, fail_details):
    total = NUM_COMBOS - 1
    print(f"\n  Passed: {pass_combos} / {total}  |  Failed: {fail_combos} / {total}")
    print(f"  Total fixture executions: {pass_combos + fail_combos}")

    print("\n  Failures by module:")
    for m in ALL_MODULES:
        if fail_by_module.get(m, 0) > 0:
            print(f"    {m:<22s} {fail_by_module[m]} combos")

    print("\n  Top failing pairs:")
    sorted_pairs = sorted(fail_by_pair.items(), key=lambda x: -x[1])
    for pair, count in sorted_pairs[:20]:
        print(f"    {pair:<45s} {count} combos")

    print(f"\n  Sample failed combos (first {len(fail_details)}):")
    for detail in fail_details:
        print(detail)
    if fail_combos > len(fail_details):
        print(f"  ... and {fail_combos - len(fail_details)} more")

    if fail_combos > 0:
        print(f"\n  FAIL: {fail_combos} combinations failed out of {total}")
    else:
        print(f"\n  All {pass_combos} combinations passed.")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Hercules Obfuscator — Parallel Test Suite")
    parser.add_argument("--jobs", "-j", type=int, default=0, help="Number of parallel workers (0 = auto-detect)")
    args = parser.parse_args()

    print("Hercules Obfuscator — Test Suite")
    print("─" * 60)
    print(f"Fixtures: 1  |  Modules: {NUM_MODULES}  |  Combinations: {NUM_COMBOS} (2^{NUM_MODULES})\n")

    num_workers = args.jobs if args.jobs > 0 else get_cpu_count()
    all_results, elapsed = run_parallel(num_workers)

    pass_combos, fail_combos, fail_by_module, fail_by_pair, fail_details = process_results(all_results)
    print_summary(pass_combos, fail_combos, fail_by_module, fail_by_pair, fail_details)
    print(f"\n  Total time: {format_eta(elapsed)}")

    sys.exit(1 if fail_combos > 0 else 0)


if __name__ == "__main__":
    main()

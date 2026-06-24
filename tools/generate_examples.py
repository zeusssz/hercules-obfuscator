#!/usr/bin/env python3
"""Generate an interactive obfuscation showcase site with lazy-loaded per-combo data."""

from __future__ import annotations

import itertools
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
SOURCES = {
    "lua": ROOT / "examples" / "sources" / "lua54-script.lua",
    "luau": ROOT / "examples" / "sources" / "luau-script.lua",
    "glua": ROOT / "examples" / "sources" / "glua-script.lua",
}
SUFFIXES = {"lua": ".lua", "luau": ".luau", "glua": ".lua"}
OUTPUT_DIR = ROOT / "examples" / "generated"
SITE_OUTPUT_DIR = OUTPUT_DIR / "site"
SITE_OUTPUT_HTML = SITE_OUTPUT_DIR / "index.html"
SITE_DATA_DIR = SITE_OUTPUT_DIR / "assets" / "data"
LUA_BIN = os.getenv("LUA_BIN") or shutil.which("lua5.4") or "lua"
WORKERS = max(1, int(os.getenv("HERCULES_EXAMPLE_WORKERS", str(os.cpu_count() or 1))))
LIMIT_PER_TARGET = max(0, int(os.getenv("HERCULES_EXAMPLE_LIMIT_PER_TARGET", "0")))


def format_eta(seconds: float) -> str:
    secs = int(seconds)
    if secs < 60:
        return f"{secs}s"
    elif secs < 3600:
        return f"{secs // 60}m {secs % 60}s"
    return f"{secs // 3600}h {(secs % 3600) // 60}m"


def main() -> int:
    manifest = load_manifest()
    methods = sorted(manifest["modules"], key=lambda item: item["bit_position"])
    method_by_key = {method["key"]: method for method in methods}
    examples: dict[str, Any] = {}

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    meta = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "manifest": manifest,
        "languages": list(SOURCES),
    }

    target_configs = []
    for target, source_path in SOURCES.items():
        source = source_path.read_text(encoding="utf-8")
        target_methods = [
            method
            for method in methods
            if target not in method.get("incompatible_with", [])
            and method.get("enabled", False)
        ]
        combos = list(iter_combinations([method["key"] for method in target_methods]))
        if LIMIT_PER_TARGET:
            combos = combos[:LIMIT_PER_TARGET]
        target_configs.append({
            "target": target,
            "source": source,
            "source_file": str(source_path.relative_to(ROOT)),
            "combos": combos,
        })

    total_combos = sum(len(tc["combos"]) for tc in target_configs)
    done = 0
    start_time = time.time()
    print(f"Generating {total_combos} examples with {WORKERS} workers")

    for tc in target_configs:
        examples[tc["target"]] = {
            "source": tc["source"],
            "source_file": tc["source_file"],
            "items": {combo_key(combo): None for combo in tc["combos"]},
        }

    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = {}
        for tc in target_configs:
            for combo in tc["combos"]:
                future = pool.submit(generate_example, tc["target"], tc["source"], combo, method_by_key)
                futures[future] = (tc["target"], combo)

        for future in as_completed(futures):
            target, combo = futures[future]
            item = future.result()
            examples[target]["items"][combo_key(combo)] = item
            done += 1
            elapsed = time.time() - start_time
            rate = done / elapsed if elapsed > 0 else 0
            remaining = total_combos - done
            eta = remaining / rate if rate > 0 else 0
            pct = (done / total_combos * 100) if total_combos > 0 else 0
            sys.stdout.write(
                f"\r  [{pct:5.1f}%] {done}/{total_combos}  "
                f"({rate:.0f}/s, ETA: {format_eta(eta)})  "
            )
            sys.stdout.flush()

    sys.stdout.write("\r" + " " * 80 + "\r")
    sys.stdout.flush()

    output = write_site(meta, examples)
    print(f"Wrote {output}")

    elapsed = time.time() - start_time
    print(f"Generated {done} combos in {format_eta(elapsed)}")
    return 0


def load_manifest() -> dict[str, Any]:
    result = subprocess.run(
        [LUA_BIN, "hercules.lua", "--manifest-json"],
        cwd=SRC,
        capture_output=True,
        text=True,
        check=True,
        timeout=30,
    )
    return json.loads(result.stdout)


def iter_combinations(methods: list[str]):
    for size in range(1, len(methods) + 1):
        yield from itertools.combinations(methods, size)


def combo_key(methods: list[str] | tuple[str, ...]) -> str:
    return "+".join(methods)


def generate_example(
    target: str, source: str, methods: list[str] | tuple[str, ...], method_by_key: dict[str, Any]
) -> dict[str, Any]:
    suffix = SUFFIXES[target]
    with tempfile.NamedTemporaryFile(
        suffix=suffix, delete=False, mode="w", encoding="utf-8"
    ) as handle:
        handle.write(source)
        path = Path(handle.name)

    flags = [method_by_key[key]["cli"]["long"] for key in methods]
    command = [
        LUA_BIN,
        "hercules.lua",
        str(path),
        "--target",
        target,
        *flags,
        "--no-watermark",
        "--overwrite",
    ]

    try:
        result = subprocess.run(
            command,
            cwd=SRC,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode != 0:
            return {
                "methods": list(methods),
                "ok": False,
                "error": (result.stdout + result.stderr)[-2000:],
                "code": "",
                "original_size": len(source),
                "obfuscated_size": 0,
            }

        code = path.read_text(encoding="utf-8")
        return {
            "methods": list(methods),
            "ok": True,
            "error": "",
            "code": code,
            "original_size": len(source),
            "obfuscated_size": len(code),
        }
    finally:
        path.unlink(missing_ok=True)


def write_site(meta: dict[str, Any], examples: dict[str, Any]) -> Path:
    shutil.rmtree(SITE_OUTPUT_DIR, ignore_errors=True)
    SITE_DATA_DIR.mkdir(parents=True, exist_ok=True)
    write_meta_file(meta)
    for target, target_examples in examples.items():
        write_data_file(target, target_examples)
    SITE_OUTPUT_HTML.write_text(render_html(), encoding="utf-8")
    return SITE_OUTPUT_HTML


def write_meta_file(meta: dict[str, Any]) -> None:
    data = json.dumps(meta, ensure_ascii=False, separators=(",", ":"))
    (SITE_DATA_DIR / "meta.js").write_text(
        "window.HERCULES_SHOWCASE_META=" + data + ";\n",
        encoding="utf-8",
    )


def write_data_file(target: str, target_examples: dict[str, Any]) -> None:
    target_dir = SITE_DATA_DIR / target
    target_dir.mkdir(parents=True, exist_ok=True)

    items_map = {}
    for idx, (combo_key, item) in enumerate(target_examples["items"].items()):
        file_id = str(idx)
        items_map[combo_key] = file_id
        (target_dir / f"{file_id}.js").write_text(
            "window.HERCULES_COMBO=window.HERCULES_COMBO||{};"
            f"window.HERCULES_COMBO[{json.dumps(target)}]="
            f"window.HERCULES_COMBO[{json.dumps(target)}]||{{}};"
            f"window.HERCULES_COMBO[{json.dumps(target)}][{json.dumps(combo_key)}]="
            + json.dumps(item, ensure_ascii=False, separators=(",", ":"))
            + ";\n",
            encoding="utf-8",
        )

    (target_dir / "index.js").write_text(
        "window.HERCULES_SHOWCASE_DATA=window.HERCULES_SHOWCASE_DATA||{};"
        f"window.HERCULES_SHOWCASE_DATA[{json.dumps(target)}]={{"
        f'"source":{json.dumps(target_examples["source"], ensure_ascii=False, separators=(",", ":"))},'
        f'"source_file":{json.dumps(target_examples["source_file"])},'
        f'"items":{json.dumps(items_map, separators=(",", ":"))}'
        f"}};\n",
        encoding="utf-8",
    )


def render_html() -> str:
    html_text = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Hercules Obfuscation Showcase</title>
  <style>
    :root {{ color-scheme: dark; --bg:#0b1020; --panel:#121a2e; --panel2:#17223b; --text:#e7edf7; --muted:#8ea0bd; --accent:#7dd3fc; --good:#86efac; --bad:#fca5a5; --border:#253553; }}
    * {{ box-sizing:border-box; }}
    body {{ margin:0; font-family:Inter, ui-sans-serif, system-ui, sans-serif; background:radial-gradient(circle at top left,#1e3a8a 0,#0b1020 36rem); color:var(--text); }}
    header {{ padding:2rem; border-bottom:1px solid var(--border); }}
    h1 {{ margin:0 0 .4rem; font-size:clamp(2rem,4vw,4rem); letter-spacing:-.05em; }}
    .sub {{ color:var(--muted); max-width:70rem; line-height:1.5; }}
    main {{ padding:1.25rem; display:grid; grid-template-columns:22rem 1fr; gap:1rem; }}
    aside,.card {{ background:linear-gradient(180deg,var(--panel),#0f172a); border:1px solid var(--border); border-radius:1rem; box-shadow:0 20px 60px #0008; }}
    aside {{ padding:1rem; position:sticky; top:1rem; height:calc(100vh - 2rem); overflow:auto; }}
    .content {{ display:grid; gap:1rem; }}
    .card {{ padding:1rem; }}
    label {{ display:block; font-size:.8rem; color:var(--muted); margin:.7rem 0 .3rem; }}
    select,button {{ width:100%; background:var(--panel2); color:var(--text); border:1px solid var(--border); border-radius:.7rem; padding:.65rem .75rem; }}
    button {{ cursor:pointer; margin:.25rem 0; }}
    button:hover {{ border-color:var(--accent); }}
    button.active {{ background:#075985; border-color:var(--accent); }}
    button:disabled {{ opacity:.35; cursor:not-allowed; }}
    .toggles {{ display:grid; gap:.25rem; }}
    .stats {{ display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:.75rem; }}
    .stat {{ background:var(--panel2); border:1px solid var(--border); border-radius:.8rem; padding:.8rem; }}
    .stat b {{ display:block; font-size:1.2rem; color:var(--accent); }}
    .panes {{ display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:1rem; align-items:start; }}
    .code-view {{ width:100%; height:72vh; overflow:auto; background:#050812; border:1px solid var(--border); border-radius:.8rem; font:13px/1.45 ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace; }}
    .code-line {{ display:grid; grid-template-columns:4.2rem minmax(0,1fr); min-width:76rem; }}
    .code-line:hover {{ background:#172033; }}
    .line-no {{ user-select:none; color:#64748b; background:#0a0f1d; border-right:1px solid var(--border); padding:0 .65rem; text-align:right; }}
    .line-no.cont {{ color:#38bdf8; }}
    .code-text {{ white-space:pre; padding:0 .75rem; }}
    .badge {{ display:inline-flex; gap:.35rem; align-items:center; border:1px solid var(--border); background:var(--panel2); color:var(--muted); padding:.25rem .5rem; border-radius:999px; margin:.15rem; font-size:.78rem; }}
    .warn {{ color:#fde68a; }}
    .error {{ color:var(--bad); white-space:pre-wrap; }}
    .loading {{ opacity:.7; }}
    @media (max-width: 900px) {{ main,.panes {{ grid-template-columns:1fr; }} aside {{ position:static; height:auto; }} .stats {{ grid-template-columns:1fr 1fr; }} }}
  </style>
</head>
<body>
  <header>
    <h1>Hercules Obfuscation Showcase</h1>
    <div class="sub">Toggle modules to instantly compare generated examples.</div>
  </header>
  <main>
    <aside>
      <label for="language">Language</label>
      <select id="language"></select>
      <label>Presets</label>
      <div id="presets"></div>
      <button id="clear">Clear</button>
      <button id="all">Select all compatible</button>
      <label>Modules</label>
      <div class="toggles" id="modules"></div>
    </aside>
    <section class="content">
      <div class="card"><div id="selection"></div><div id="notice" class="warn"></div></div>
      <div class="stats" id="stats"></div>
      <div class="panes">
        <div class="card"><h2>Source</h2><div class="code-view" id="source"></div></div>
        <div class="card"><h2>Obfuscated</h2><div class="code-view" id="output"></div></div>
      </div>
    </section>
  </main>
  <script src="assets/data/meta.js"></script>
  <script>
    const $ = id => document.getElementById(id);
    const META = window.HERCULES_SHOWCASE_META;
    if (!META) {
      $('selection').innerHTML = '<span class="badge">Data files did not load</span>';
      $('notice').textContent = 'The browser could not read assets/data/*.js. If this was opened through file:// or a Flatpak file portal, run `make examples-serve` and open http://127.0.0.1:8989/ instead.';
      throw new Error('Showcase data files did not load');
    }
    window.HERCULES_SHOWCASE_DATA = window.HERCULES_SHOWCASE_DATA || {};
    window.HERCULES_COMBO = window.HERCULES_COMBO || {};
    const loadedLangs = new Set();

    const methods = [...META.manifest.modules].sort((a,b)=>a.bit_position-b.bit_position);
    const methodByKey = Object.fromEntries(methods.map(m=>[m.key,m]));
    const presets = META.manifest.presets || [];
    const languages = META.languages || ['lua','luau','glua'];
    let lang = 'lua';
    let selected = new Set();

    function comboKey(keys) {{ return [...keys].filter(Boolean).sort((a,b)=>methodByKey[a].bit_position-methodByKey[b].bit_position).join('+'); }}
    function compatible(m) {{ return !(m.incompatible_with || []).includes(lang); }}
    function displayName(key) {{ return methodByKey[key]?.name || key; }}
    function escapeHtml(value) {{ return value.replace(/[&<>]/g, ch => ({{'&':'&amp;','<':'&lt;','>':'&gt;'}})[ch]); }}
    function renderCode(target, code) {{
      const wrap = 120;
      const lines = code.split('\\n');
      target.innerHTML = lines.map((line, index) => {{
        const chunks = line.length ? line.match(new RegExp(`.{{1,${{wrap}}}}`, 'g')) : [''];
        return chunks.map((chunk, chunkIndex) => {{
          const number = chunkIndex === 0 ? String(index + 1) : '\u21aa';
          const cls = chunkIndex === 0 ? 'line-no' : 'line-no cont';
          return `<div class="code-line"><span class="${{cls}}">${{number}}</span><span class="code-text">${{escapeHtml(chunk)}}</span></div>`;
        }}).join('');
      }}).join('');
    }}
    function currentItem() {{
      const data = window.HERCULES_SHOWCASE_DATA[lang];
      if (!data) return null;
      const key = comboKey(selected);
      if (!key) return null;
      return (window.HERCULES_COMBO[lang] || {{}})[key] || null;
    }}
    function loadLanguageData(nextLang) {{
      if (loadedLangs.has(nextLang)) return Promise.resolve();
      return new Promise((resolve, reject) => {{
        const script = document.createElement('script');
        script.src = `assets/data/${{nextLang}}/index.js`;
        script.onload = () => {{ loadedLangs.add(nextLang); resolve(); }};
        script.onerror = () => reject(new Error(`Failed to load ${{script.src}}. Run make examples-serve and open http://127.0.0.1:8989/ if file:// is restricted.`));
        document.head.appendChild(script);
      }});
    }}
    function loadComboData(lookupKey) {{
      const data = window.HERCULES_SHOWCASE_DATA[lang];
      if (!data) return Promise.reject(new Error('Language data not loaded'));
      if (!lookupKey || lookupKey in (window.HERCULES_COMBO[lang] || {{}})) return Promise.resolve();
      const fileId = data.items[lookupKey];
      if (fileId == null) return Promise.resolve();
      return new Promise((resolve, reject) => {{
        const script = document.createElement('script');
        script.src = `assets/data/${{lang}}/${{fileId}}.js`;
        script.onload = () => {{ resolve(); }};
        script.onerror = () => reject(new Error(`Failed to load combo data for ${{lookupKey}}`));
        document.head.appendChild(script);
      }});
    }}
    function renderLanguage() {{
      $('language').innerHTML = languages.map(l => `<option value="${{l}}">${{l.toUpperCase()}}</option>`).join('');
      $('language').value = lang;
      $('language').onchange = e => {{
        lang = e.target.value;
        selected = new Set([...selected].filter(k => compatible(methodByKey[k])));
        renderShell();
        loadLanguageData(lang).then(renderContent).catch(err => renderCode($('output'), String(err)));
      }};
    }}
    function renderPresets() {{
      $('presets').innerHTML = presets.map(p => `<button data-preset="${{p.key}}">${{p.key}}</button>`).join('');
      document.querySelectorAll('[data-preset]').forEach(btn => btn.onclick = () => {{
        const preset = presets.find(p => p.key === btn.dataset.preset);
        selected = new Set((preset.methods || []).filter(k => methodByKey[k] && compatible(methodByKey[k])));
        renderShell();
        renderContent();
      }});
    }}
    function renderModules() {{
      $('modules').innerHTML = methods.map(m => {{
        const disabled = !compatible(m);
        const active = selected.has(m.key);
        const title = disabled ? `Incompatible with ${{lang}}` : m.description;
        return `<button title="${{title}}" data-method="${{m.key}}" class="${{active?'active':''}}" ${{disabled?'disabled':''}}>${{m.name}}</button>`;
      }}).join('');
      document.querySelectorAll('[data-method]').forEach(btn => btn.onclick = () => {{
        const key = btn.dataset.method;
        if (selected.has(key)) selected.delete(key); else selected.add(key);
        renderShell();
        renderContent();
      }});
    }}
    function renderContent() {{
      const data = window.HERCULES_SHOWCASE_DATA[lang];
      if (!data) return;
      const source = data.source;
      const key = comboKey(selected);
      renderCode($('source'), source);
      $('selection').innerHTML = [...selected].sort((a,b)=>methodByKey[a].bit_position-methodByKey[b].bit_position).map(k => `<span class="badge">${{displayName(k)}}</span>`).join('') || '<span class="badge">No modules selected</span>';
      $('notice').textContent = '';
      if (!selected.size) {{
        renderCode($('output'), source);
        renderStats(source.length, source.length, false);
        return;
      }}
      const item = currentItem();
      if (!item && key && !(key in (window.HERCULES_COMBO[lang] || {{}}))) {{
        $('output').className = 'code-view loading';
        renderCode($('output'), 'Loading...');
        loadComboData(key).then(renderContent).catch(err => {{ renderCode($('output'), String(err)); $('output').className = 'code-view error'; }});
        return;
      }}
      if (!item) {{
        renderCode($('output'), selected.size ? 'This exact combination was not generated.' : source);
        renderStats(source.length, selected.size ? 0 : source.length, false);
        return;
      }}
      renderCode($('output'), item.ok ? item.code : item.error);
      $('output').className = item.ok ? 'code-view' : 'code-view error';
      renderStats(item.original_size, item.obfuscated_size, item.ok);
    }}
    function renderStats(original, obfuscated, ok) {{
      const ratio = original ? ((obfuscated / original) * 100).toFixed(1) + '%' : 'n/a';
      $('stats').innerHTML = [
        ['Target', lang.toUpperCase()], ['Generated', ok ? 'yes' : 'no'], ['Original', original + ' B'], ['Output', obfuscated + ' B'], ['Ratio', ratio], ['Examples', Object.keys(window.HERCULES_SHOWCASE_DATA[lang].items).length], ['Created', META.generated_at.replace('T',' ').replace(/\\.\\d+.*/, ' UTC')], ['Source', window.HERCULES_SHOWCASE_DATA[lang].source_file]
      ].map(([k,v]) => `<div class="stat"><span>${{k}}</span><b>${{v}}</b></div>`).join('');
    }}
    function renderShell() {{ renderLanguage(); renderPresets(); renderModules(); }}
    $('clear').onclick = () => {{ selected.clear(); renderShell(); renderContent(); }};
    $('all').onclick = () => {{ selected = new Set(methods.filter(compatible).map(m=>m.key)); renderShell(); renderContent(); }};
    renderShell();
    loadLanguageData(lang).then(renderContent).catch(err => renderCode($('output'), String(err)));
  </script>
</body>
</html>
"""
    return html_text.replace("{{", "{").replace("}}", "}")


if __name__ == "__main__":
    raise SystemExit(main())

# Hercules Obfuscation Showcase

Run from the repository root:

```bash
make examples
```

This generates the showcase site at:

```text
examples/generated/site/index.html
examples/generated/site/assets/data/<lang>/*.js
```

To test the build locally, run `make examples-serve` and open
`http://127.0.0.1:8989/`.

The generator uses the committed source files in `examples/sources/` and the
Obfuscator manifest to build all compatible method combinations. Combo data
is lazy-loaded on demand for fast initial page load.

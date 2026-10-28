# Local builds (Windows x64 & Linux x64 .deb)

This repository is a copy of Pumpkin. Two helper scripts are provided:

- `build-windows.ps1` -> `dist\pumpkin-windows-x64.exe`
- `build-linux-deb.ps1` -> `dist\pumpkin_*_amd64.deb`

## Prerequisites

1. Rust toolchain (stable, >= 1.96):
   ```
   rustup update stable
   rustup default stable
   ```
2. Zig (for cross-compiling to Linux):
   - Download from https://ziglang.org/download/ and put `zig.exe` on PATH, or
   - leave it in `C:\Users\<you>\Downloads\zig-x86_64-windows-0.17.0\zig-x86_64-windows-0.17.0\`
3. cargo-zigbuild:
   ```
   cargo install cargo-zigbuild --locked
   ```
4. cargo-deb:
   ```
   cargo install cargo-deb --locked
   ```

## Build

Windows x64:
```
.\build-windows.ps1          # fast (LTO off)
.\build-windows.ps1 -Full    # full release (LTO on, slower)
```

Linux x64 .deb (cross-built from Windows):
```
.\build-linux-deb.ps1        # fast (LTO off)
.\build-linux-deb.ps1 -Full  # full release (LTO on, slower)
```

## Notes

- The default `Cargo.toml` release profile uses fat LTO (`lto = true`, `codegen-units = 1`),
  which can take a long time on Windows. The scripts disable LTO by default for local builds.
  Use `-Full` to produce a binary matching the official release profile.
- `cargo-deb` needs `strip`/`dpkg-shlibdeps` on Linux; when cross-building from Windows those
  are unavailable, so the scripts pass `--no-strip` and set `depends` manually in
  `crates/pumpkin/Cargo.toml`.
- The server writes its config/world into the current working directory, so run the binary
  from an empty data directory.
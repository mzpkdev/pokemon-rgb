# Installation

Pokémon RGB uses the same pinned build toolchain as CI: RGBDS v1.0.1.

## Prerequisites

Install Git, GNU Make, a C compiler, `bison`, `libpng`, and `pkg-config`.
Platform-specific RGBDS prerequisites are documented in the
[RGBDS installation guide](https://rgbds.gbdev.io/install).

## Clone and build

```console
git clone https://github.com/mzpkdev/pokemon-rgb.git
cd pokemon-rgb
make -j4
```

This builds the Red, Blue, Green, Red debug, and Blue debug ROM variants.

## Use a local RGBDS installation

To keep RGBDS v1.0.1 inside the repository instead of installing it globally,
build RGBDS with a local prefix and pass its `bin` directory to Make:

```console
make RGBDS=rgbds-1.0.1/bin/
```

## Run tests

Install the pinned Python dependencies and run pytest:

```console
python -m pip install -r tools/rom_tests/requirements.txt
python -m pytest
```

To reproduce GitHub Actions locally, install
[nektos/act](https://github.com/nektos/act), ensure Docker is running, and use:

```console
python tools/run_ci.py
```

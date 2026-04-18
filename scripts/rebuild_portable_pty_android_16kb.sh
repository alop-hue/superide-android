#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PORTABLE_PTY_DIR="${PORTABLE_PTY_DIR:-}"
if [[ -z "$PORTABLE_PTY_DIR" ]]; then
  PORTABLE_PTY_DIR="$(ls -d "$HOME"/.pub-cache/hosted/pub.dev/portable_pty-* 2>/dev/null | sort -V | tail -n 1 || true)"
fi

if [[ -z "$PORTABLE_PTY_DIR" || ! -d "$PORTABLE_PTY_DIR/rust" ]]; then
  echo "Could not find portable_pty Rust sources." >&2
  echo "Set PORTABLE_PTY_DIR to your portable_pty package path and retry." >&2
  exit 1
fi

RUSTUP_TOOLCHAIN_NAME="${RUSTUP_TOOLCHAIN_NAME:-stable}"

if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
  NDK_ROOT="$ANDROID_NDK_HOME"
elif [[ -n "${ANDROID_NDK_ROOT:-}" ]]; then
  NDK_ROOT="$ANDROID_NDK_ROOT"
elif [[ -d "$HOME/Android/ndk/27.0.12077973" ]]; then
  NDK_ROOT="$HOME/Android/ndk/27.0.12077973"
else
  NDK_ROOT="$(ls -d "$HOME"/Android/ndk/* 2>/dev/null | sort -V | tail -n 1 || true)"
fi

if [[ -z "$NDK_ROOT" || ! -d "$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin" ]]; then
  echo "Android NDK not found." >&2
  echo "Set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) and retry." >&2
  exit 1
fi

TOOLCHAIN_BIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
RUST_DIR="$PORTABLE_PTY_DIR/rust"
PREBUILT_ROOT="$ROOT_DIR/.prebuilt"

mkdir -p "$PREBUILT_ROOT"

build_abi() {
  local abi="$1"
  local target
  local platform_label
  local clang
  local cc_var
  local linker_var

  case "$abi" in
    arm64-v8a)
      target="aarch64-linux-android"
      platform_label="android-arm64"
      clang="$TOOLCHAIN_BIN/aarch64-linux-android21-clang"
      cc_var="CC_aarch64_linux_android"
      linker_var="CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER"
      ;;
    armeabi-v7a)
      target="armv7-linux-androideabi"
      platform_label="android-arm"
      clang="$TOOLCHAIN_BIN/armv7a-linux-androideabi21-clang"
      cc_var="CC_armv7_linux_androideabi"
      linker_var="CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER"
      ;;
    x86_64)
      target="x86_64-linux-android"
      platform_label="android-x64"
      clang="$TOOLCHAIN_BIN/x86_64-linux-android21-clang"
      cc_var="CC_x86_64_linux_android"
      linker_var="CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER"
      ;;
    *)
      echo "Unsupported ABI: $abi" >&2
      exit 1
      ;;
  esac

  local out_dir="$PREBUILT_ROOT/$platform_label"
  local out_lib="$out_dir/libportable_pty_rs.so"

  mkdir -p "$out_dir"

  echo "Building portable_pty for $abi ($target)..."
  (
    cd "$RUST_DIR"
    RUSTUP_TOOLCHAIN="$RUSTUP_TOOLCHAIN_NAME" rustup target add "$target" >/dev/null

    local rustflags="${RUSTFLAGS:-}"
    rustflags="$rustflags -C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384"

    env \
      RUSTUP_TOOLCHAIN="$RUSTUP_TOOLCHAIN_NAME" \
      "$cc_var=$clang" \
      AR_aarch64_linux_android="$TOOLCHAIN_BIN/llvm-ar" \
      AR_armv7_linux_androideabi="$TOOLCHAIN_BIN/llvm-ar" \
      AR_x86_64_linux_android="$TOOLCHAIN_BIN/llvm-ar" \
      "$linker_var=$clang" \
      RUSTFLAGS="$rustflags" \
      cargo build --release --target "$target"

    cp -f "target/$target/release/libportable_pty_rs.so" "$out_lib"
  )

  local first_align
  first_align="$(readelf -W -l "$out_lib" | awk '/LOAD/{print $NF; exit}')"
  if [[ "$first_align" != "0x4000" ]]; then
    echo "Unexpected ELF alignment for $out_lib: $first_align" >&2
    exit 1
  fi

  echo "Wrote $out_lib (LOAD align: $first_align)"
}

if [[ "${1:-}" == "--all-abis" ]]; then
  build_abi arm64-v8a
  build_abi armeabi-v7a
  build_abi x86_64
else
  build_abi arm64-v8a
fi

echo "Done. portable_pty build hook will prefer .prebuilt/* over downloaded artifacts."

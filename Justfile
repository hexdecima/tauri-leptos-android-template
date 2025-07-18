_default:
  just --list

watch:
  bacon clippy

dev:
  cargo tauri android dev

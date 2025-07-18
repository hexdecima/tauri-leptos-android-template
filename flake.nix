{
  description =
    "a development environment for Android apps, with Tauri and Leptos.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    parts.url = "github:hercules-ci/flake-parts";
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, parts, rust, ... }:
    parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { system, ... }:
        let
          overlays = [ (import rust) ];
          pkgs = import nixpkgs {
            inherit system overlays;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile
            ./rust-toolchain.toml;
        in {
          devShells.default = let
            inherit (pkgs) lib;
            # see: https://nixos.org/manual/nixpkgs/unstable/#android
            androidComposition = pkgs.androidenv.composeAndroidPackages {
              includeNDK = true;
              includeEmulator = false;
              buildToolsVersions = [ "34.0.0" ];
              platformVersions = [ "34" ];
              cmakeVersions = [ "3.10.2" ];
            };
            androidSdk = androidComposition.androidsdk;
            platformTools = androidComposition.platform-tools;
            jdk = pkgs.jdk21_headless; # define it here so changing is easy.

            JAVA_HOME = jdk.home;
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";
          in pkgs.mkShell {
            inherit JAVA_HOME ANDROID_HOME ANDROID_NDK_ROOT;
            # TODO: write this in a less ugly way.
            PKG_CONFIG_PATH = with pkgs;
              "${glib.dev}/lib/pkgconfig:${libsoup_3.dev}/lib/pkgconfig:${webkitgtk_4_1.dev}/lib/pkgconfig:${at-spi2-atk.dev}/lib/pkgconfig:${gtk3.dev}/lib/pkgconfig:${gdk-pixbuf.dev}/lib/pkgconfig:${cairo.dev}/lib/pkgconfig:${pango.dev}/lib/pkgconfig:${harfbuzz.dev}/lib/pkgconfig";
            LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ glib ]);
            NIX_LD = "${pkgs.stdenv.cc.libc}/lib/ld-linux-x86-64.so.2";

            name = "tauri_leptos_android";
            buildInputs = let
              devTools = with pkgs; [
                rustToolchain
                rustup
                nil
                taplo
                nixfmt-classic
                vscode-langservers-extracted
                just
                bacon
              ];
              tauriDeps = with pkgs; [
                pkg-config
                cargo-tauri
                at-spi2-atk
                gobject-introspection
                atkmm
                cairo
                gdk-pixbuf
                glib
                gobject-introspection.dev
                gtk3
                harfbuzz
                librsvg
                libsoup_3
                pango
                webkitgtk_4_1
                webkitgtk_4_1.dev
              ];
              androidDeps = [ androidSdk platformTools jdk ];
              leptosDeps = with pkgs; [ trunk ];
            in devTools ++ tauriDeps ++ androidDeps ++ leptosDeps;
            shellHook = ''
              export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
            '';
          };
        };
    };
}

{
  description = "Spencer Macro Utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        runtimeLibs = with pkgs; [
          stdenv.cc.cc.lib
          alsa-lib
          pulseaudio
          libjack2
          sndio
          libX11
          libXext
          libXrandr
          libXcursor
          libXfixes
          libXi
          libXScrnSaver
          libXtst
          libxkbcommon
          libdrm
          libxcb-util
          libxcb
          mesa
          dbus
          ibus
          udev
          libthai
          fribidi
          libglvnd
          libgbm
        ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "suspend";
          version = "3.2.2";

          src = pkgs.fetchFromGitHub {
            owner = "Spencer0187";
            repo = "Spencer-Macro-Utilities";
            rev = "92c01fb2dd58b32400fd35db23d722ea514aeed9";
            sha256 = "sha256-gVbcPm6jVIwFzU2aoX2HnqeMdE/3R1WMLFX/oM5mnqE=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            makeWrapper
            patchelf
          ];

          buildInputs = runtimeLibs;

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DSMU_BUNDLE_SDL3=ON"
            "-DSMU_LINK_SDL3_STATIC=OFF"
          ];

          buildPhase = ''
            runHook preBuild
            cmake --build . --target package-linux-dir --parallel $NIX_BUILD_CORES
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            local pkgDir="SpencerMacroUtilities"
            local runtimeLibPath="${pkgs.lib.makeLibraryPath runtimeLibs}"

            mkdir -p "$out/bin" "$out/share/suspend"

            install -m755 "$pkgDir/suspend" "$out/share/suspend/suspend"
            patchelf --remove-rpath "$out/share/suspend/suspend"
            patchelf --set-rpath "$runtimeLibPath:$out/share/suspend/lib" \
              "$out/share/suspend/suspend"

            cp -r "$pkgDir/assets" "$out/share/suspend/assets"

            if [ -d "$pkgDir/lib" ]; then
              cp -r "$pkgDir/lib" "$out/share/suspend/lib"
            fi

            [ -f "$pkgDir/LINUX_SETUP.md" ] && cp "$pkgDir/LINUX_SETUP.md" "$out/share/suspend/LINUX_SETUP.md"

            if [ -d "$pkgDir/scripts" ]; then
              cp -r "$pkgDir/scripts" "$out/share/suspend/scripts"
            fi

            makeWrapper "$out/share/suspend/suspend" "$out/bin/suspend" \
              --chdir "$out/share/suspend" \
              --set LD_LIBRARY_PATH "$runtimeLibPath:$out/share/suspend/lib"

            mkdir -p "$out/share/pixmaps" "$out/share/applications"
            cp "$src/public/favicon.ico" "$out/share/pixmaps/suspend.ico"

            cat > "$out/share/applications/suspend.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Spencer Macro Utilities
Exec=$out/bin/suspend %u
Icon=$out/share/pixmaps/suspend.ico
Comment=Launch Spencer Macro Utilities
Categories=Utility;
Terminal=false
EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Spencer Macro Utilities";
            mainProgram = "suspend";
            platforms = platforms.linux;
            license = licenses.gpl3Only;
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${stdenv.hostPlatform.system}.default;
        };
      })
    // {
      nixosModules.default = import ./module.nix;
    };
}

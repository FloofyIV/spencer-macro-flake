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
          alsa-lib pulseaudio libjack2 sndio
          libX11 libXext libXrandr libXcursor
          libXfixes libXi libXScrnSaver libXtst
          libxkbcommon libdrm libxcb-util libxcb
          mesa dbus ibus udev libthai fribidi
          libglvnd libgbm
        ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "suspend";
          version = "3.2.2";

          src = pkgs.fetchFromGitHub {
            owner = "Spencer0187";
            repo = "Spencer-Macro-Utilities";
            rev = "7105b1c";
            sha256 = "sha256-0i9izGE/9LunuI6ZHvN2xrq9EcRdoiUnvVlXf5XidJM=";
          };

          nativeBuildInputs = with pkgs; [
            cmake ninja pkg-config makeWrapper
          ];

          buildInputs = runtimeLibs;

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
          ];

          postInstall = ''
            mkdir -p $out/bin

            if [ -f $out/suspend ]; then
              chmod +x $out/suspend
            fi

            cat > $out/run.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR=$(cd "$(dirname "$0")" && pwd)
export LD_LIBRARY_PATH="$APP_DIR/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

exec "$APP_DIR/suspend" "$@"
EOF

            chmod +x $out/run.sh

            cat > $out/bin/suspend <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REAL_RUN="$BASE_DIR/run.sh"

exec "$REAL_RUN" "$@"
EOF

            chmod +x $out/bin/suspend
mkdir -p $out/share/pixmaps
cp $src/public/favicon.ico $out/share/pixmaps/suspend.ico
Icon=$out/share/pixmaps/suspend.ico
mkdir -p $out/share/applications
            cat > $out/share/applications/suspend.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Spencer Macro Utilities
Exec=$out/bin/suspend %u
Icon=system-run
Comment=Launch Spencer Macro Utilities
Categories=Utility;
Terminal=false
EOF

            chmod 644 $out/share/applications/suspend.desktop
          '';

          postFixup = ''
            wrapProgram $out/suspend \
              --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          '';

          meta = {
            mainProgram = "suspend";
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      })
    // {
      nixosModules.default = import ./module.nix;
    };
}

{
  description = "Dino";

  inputs.nixpkgs.url = github:nixos/nixpkgs?ref=nixos-23.11;

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
  in {
    packages.x86_64-linux = {
      gupnp-igd_1_6 = (pkgs.gupnp-igd.overrideAttrs (old: rec {
        version = "1.6.0";
        src = pkgs.fetchurl {
          url = "mirror://gnome/sources/${old.pname}/${pkgs.lib.versions.majorMinor version}/${old.pname}-${version}.tar.xz";
          hash = "sha256-QJmXgzmrIhJtSWjyozK20JT8RMeHl4YHgfH8LxF3G3Q=";
        };
      })).override { gupnp = pkgs.gupnp_1_6; };
      libnice = (pkgs.libnice.override { gupnp-igd = self.packages.x86_64-linux.gupnp-igd_1_6; }).overrideAttrs (old: {
        postPatch = ''
          sed -i 's/gupnp-igd-1.0/gupnp-igd-1.6/g' meson.build
        '';
      });
      default = with pkgs; callPackage ./default.nix {
        inherit (gst_all_1) gstreamer gst-plugins-base gst-plugins-bad gst-vaapi;
        gst-plugins-good = gst_all_1.gst-plugins-good.override { gtkSupport = true; };
        libnice = self.packages.x86_64-linux.libnice;
        libsoup = pkgs.libsoup_3;
      };
    };
    devShells.x86_64-linux.default = with pkgs; mkShell {
      inputsFrom = [ self.packages.x86_64-linux.default ];
      cmakeFlags = self.packages.x86_64-linux.default.cmakeFlags;
      mesonFlags = self.packages.x86_64-linux.default.mesonFlags;
      packages = [ gdb valgrind ninja ];
      hardeningDisable = [ "all" ];
      shellHook = ''
        export XDG_DATA_DIRS=$GSETTINGS_SCHEMAS_PATH:$XDG_ICON_DIRS:$XDG_DATA_DIRS
        __GIO_EXTRA_MODULES=$(echo "''${gappsWrapperArgs[@]}" | grep -Po 'GIO_EXTRA_MODULES\s*:\s*\K([^ ]+)' | xargs printf ":%s")
        export GIO_EXTRA_MODULES+=$__GIO_EXTRA_MODULES
        export CMAKE_GENERATOR=Ninja
      '';
    };
  };
}

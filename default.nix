# {
#   system ? builtins.currentSystem,
#   sources ? import ./nix/sources.nix,
# }:
let
  pkgs = import <nixpkgs> { };
    # pkgs = (import sources.nixpkgs { overlays=[(import ./zig-master.nix )]; }).pkgsCross.i686-embedded;
in
# pkgs.callPackage ./coolos.nix { }
pkgs.callPackage ./zig-master.nix {}
# {
#   system ? builtins.currentSystem,
#   sources ? import ./nix/sources.nix,
# }:
let
  pkgs = import <nixpkgs> { };
    # pkgs = (import sources.nixpkgs { overlays=[(import ./zig-master.nix )]; }).pkgsCross.i686-embedded;
  zig-master = pkgs.callPackage ./zig-master.nix { };
in
pkgs.callPackage ./coolos.nix { 
  inherit zig-master; # Equal to zig-master = zig-master;
}
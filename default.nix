{
  system ? builtins.currentSystem,
  sources ? import ./nix/sources.nix,
}:
let
    pkgs = (import sources.nixpkgs {}).pkgsCross.i686-embedded;
in
# pkgs.callPackage ./coolos.nix { }
pkgs.callPackage ./zig-master.nix {}
# {
#   system ? builtins.currentSystem,
#   sources ? import ./nix/sources.nix,
# }:
let
  pkgs = import <nixpkgs> { };
    # pkgs = (import sources.nixpkgs { overlays=[(import ./zigMaster.nix )]; }).pkgsCross.i686-embedded;
  zigMaster = pkgs.callPackage ./zigMaster.nix { };
in
pkgs.callPackage ./coolos.nix { 
  inherit zigMaster; # Equal to zigMaster = zigMaster;
}
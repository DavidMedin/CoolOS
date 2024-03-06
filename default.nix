{
  system ? builtins.currentSystem,
  sources ? import ./nix/sources.nix,
}:
let
#   pkgs = import sources.nixpkgs {
#     config = { };
#     overlays = [ ];
#     inherit system;
#   };
    # nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarballs/release-22.11";
    pkgs = (import sources.nixpkgs {}).pkgsCross.i686-embedded;
in
pkgs.callPackage ./coolos.nix { }
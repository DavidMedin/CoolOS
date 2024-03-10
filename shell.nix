let
  pkgs = import <nixpkgs> { };
  zigMaster = pkgs.callPackage ./zigMaster.nix { };
  zlsMaster = pkgs.callPackage ./zlsMaster.nix { inherit zigMaster; };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [ zigMaster zlsMaster ];
}
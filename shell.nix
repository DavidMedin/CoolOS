let
  pkgs = import <nixpkgs> { };
  zig-master = pkgs.callPackage ./zig-master.nix { };
  # zls-master = pkgs.callPackage ./zls-master.nix { inherit zig-master; };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [ zig-master  ];
}
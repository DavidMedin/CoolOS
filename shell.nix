with
  import <nixpkgs> { };
mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [ (callPackage ./zig-master.nix { }) ];
}
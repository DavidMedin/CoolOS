{
  lib,
  stdenv,
  nasm,
  grub2,
  libisoburn
}:
let
    fs = lib.fileset;

    # Use this whole folder as a source.
    sourceFiles = ./.;
in
stdenv.mkDerivation {
  pname = "cool-os";
  version = "v1.1.1";

  # What are the source files?
  src = fs.toSource {
    root = ./.;
    fileset = sourceFiles;
  };

  # what packages do I need to build (host tuple)
  nativeBuildInputs = [ nasm grub2 libisoburn zig-master ];

  # what packages to I need to build (build tuple)
  buildInputs = [ ];

  postInstall = ''
    mkdir -p $out
    cp -v coolos.img $out
    cp -v coolos.bin $out
  '';
}

{
  lib,
  stdenv,
  # nasm,
  # grub2,
  # libisoburn
  zigMaster,
}:
let
    fs = lib.fileset;

    # Use this whole folder as a source.
    sourceFiles = ./.;
in
stdenv.mkDerivation {
  pname = "cool-os";
  version = "v1.1.2";

  # What are the source files?
  src = fs.toSource {
    root = ./.;
    fileset = sourceFiles;
  };

  # what packages do I need to build (host tuple)
  nativeBuildInputs = [  zigMaster ]; # nasm grub2 libisoburn

  # what packages to I need to build (build tuple)
  buildInputs = [ ];

  # buildPhase = ''
  # zig build
  # '';

  postInstall = ''
    mkdir -p $out
    cp zig-out/bin/* $out
  '';
  # cp -v coolos.img $out
  # cp -v coolos.bin $out
}

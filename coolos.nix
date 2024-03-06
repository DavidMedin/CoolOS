{
  lib,
  stdenv,
  nasm,
  grub2,
  libisoburn
}:
let
    fs = lib.fileset;
    sourceFiles = ./.;
in
fs.trace sourceFiles
stdenv.mkDerivation {
  pname = "cool-os";
  version = "v1.1.1";

  src = fs.toSource {
    root = ./.;
    fileset = sourceFiles;
  };

  nativeBuildInputs = [ nasm grub2 libisoburn ];
  buildInputs = [ ];

  buildPhase = ''
  make
  '';
  postInstall = ''
    mkdir -p $out
    cp -v coolos.img $out
    cp -v coolos.bin $out
  '';
}

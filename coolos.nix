{
  lib,
  stdenv,
  nasm
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

  nativeBuildInputs = [ nasm ];
  buildInputs = [ ];

  postInstall = ''
    mkdir $out
    cp -v coolos.img $out
  '';
}

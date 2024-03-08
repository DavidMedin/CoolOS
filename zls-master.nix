{ lib
, stdenv
, fetchgit
, callPackage
, zig-master
}:

stdenv.mkDerivation {
  name = "zls-master";

  src = fetchgit {
    # owner = "ziglang";
    # repo = "zig";
    url = "https://github.com/zigtools/zls";
    rev = "ac60c30661cb4c371106c330d4a851fbd61c4d9e";
    hash = "sha256-5T4T9F165C7JN2ZgaelQtEFqmP7NbzXleh1kxbNkGzE=";
    # inherit (args) hash;
  };

#   nativeBuildInputs = [
#     # cmake
#     llvmPackages_17.llvm.dev
#   ];

#   buildInputs = [
#     libxml2
#     zlib
#     stdenv.cc.cc.lib
#     zig-master
#   ] ++ (with llvmPackages_17; [
#     libclang
#     lld
#     llvm
#   ]);
    nativeBuildInputs = [ zig-master.hook ];

#   env.ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";

  # Zig's build looks at /usr/bin/env to find dynamic linking info. This doesn't
  # work in Nix's sandbox. Use env from our coreutils instead.
#   postPatch = ''
#     substituteInPlace lib/std/zig/system.zig \
#       --replace "/usr/bin/env" "${coreutils}/bin/env"
#   '';
# 
#   doInstallCheck = true;
    postPatch = ''
    ln -s ${callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
    '';
#   installCheckPhase = ''
#     runHook preInstallCheck

#     $out/bin/zig test --cache-dir "$TMPDIR/zig-test-cache" -I $src/test $src/test/behavior.zig

#     runHook postInstallCheck
#   '';

#   passthru = {
#     hook = callPackage ./hook.nix {
#       zig = finalAttrs.finalPackage;
#     };
#   };

  meta = {
    description = "zls, duh";
    homepage = "https://ziglang.org/";
    # changelog = "https://ziglang.org/download/${finalAttrs.version}/release-notes.html";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ andrewrk ] ++ lib.teams.zig.members;
    platforms = lib.platforms.unix;
  };
} #// removeAttrs args [ "hash" ])
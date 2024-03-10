{ lib
, stdenv
, fetchzip
# , cmake
# , llvmPackages_17
# , libxml2
# , zlib
, coreutils
, callPackage,
autoPatchelfHook
}:

stdenv.mkDerivation (finalAttrs: {
  name = "zigMaster";
  version = "0.12.0";
  src = fetchzip {
    url = "https://ziglang.org/builds/zig-linux-x86_64-0.12.0-dev.3192+e2cbbd0c2.tar.xz";
    # rev = "9d500bda2d09fe67c39ee98067c1e53c58adbd5e";
    hash = "sha256-zrDxmwchQaBzGiWGMt1s5hLw3I2YkITxqdacI0FoUz0=";
  };

  nativeBuildInputs = [
    # cmake
    # llvmPackages_17.llvm.dev
    autoPatchelfHook
  ];

  buildInputs = [
    # libxml2
    # zlib
    # stdenv.cc.cc.lib
  ];
  #  ++ (with llvmPackages_17; [
  #   libclang
  #   lld
  #   llvm
  # ]);

  env.ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";

  # Zig's build looks at /usr/bin/env to find dynamic linking info. This doesn't
  # work in Nix's sandbox. Use env from our coreutils instead.
  # postPatch = ''
  #   substituteInPlace lib/std/zig/system.zig \
  #     --replace "/usr/bin/env" "${coreutils}/bin/env"
  # '';

  # doInstallCheck = true;
  # installCheckPhase = ''
  #   runHook preInstallCheck

  #   $out/bin/zig test --cache-dir "$TMPDIR/zig-test-cache" -I $src/test $src/test/behavior.zig

  #   runHook postInstallCheck
  # '';

  passthru = {
    hook = callPackage ./hook.nix {
      zigMaster = finalAttrs.finalPackage;
    };
  };


  sourceRoot = ".";


  installPhase = ''
  runHook preInstall
  install -m755 -D source/zig $out/bin/zig
  runHook postInstall
  '';

  meta = {
    description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
    homepage = "https://ziglang.org/";
    # changelog = "https://ziglang.org/download/${finalAttrs.version}/release-notes.html";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ andrewrk ] ++ lib.teams.zig.members;
    platforms = lib.platforms.unix;
  };
})
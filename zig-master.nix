{ lib
, stdenv
, fetchgit
, cmake
, llvmPackages_17
, libxml2
, zlib
, coreutils
, callPackage,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "zig-master";
  version = "0.12.0";
  src = fetchgit {
    # owner = "ziglang";
    # repo = "zig";
    url = "https://github.com/ziglang/zig";
    rev = "377ecc6afb14a112a07c6d2c3570e2b77b12a116";
    hash = "sha256-flxB3IbngjgBwJeGGx4oDAw0AIi7SfJ5Z9vbRZkoUKs=";
    # inherit (args) hash;
  };

  nativeBuildInputs = [
    cmake
    llvmPackages_17.llvm.dev
  ];

  buildInputs = [
    libxml2
    zlib
    stdenv.cc.cc.lib
  ] ++ (with llvmPackages_17; [
    libclang
    lld
    llvm
  ]);

  env.ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";

  # Zig's build looks at /usr/bin/env to find dynamic linking info. This doesn't
  # work in Nix's sandbox. Use env from our coreutils instead.
  postPatch = ''
    substituteInPlace lib/std/zig/system.zig \
      --replace "/usr/bin/env" "${coreutils}/bin/env"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/zig test --cache-dir "$TMPDIR/zig-test-cache" -I $src/test $src/test/behavior.zig

    runHook postInstallCheck
  '';

  passthru = {
    hook = callPackage ./hook.nix {
      zig-master = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
    homepage = "https://ziglang.org/";
    # changelog = "https://ziglang.org/download/${finalAttrs.version}/release-notes.html";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ andrewrk ] ++ lib.teams.zig.members;
    platforms = lib.platforms.unix;
  };
})
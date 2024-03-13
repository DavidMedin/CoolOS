const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
    } });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug
    }); // defaults to debug

    // const lib = b.addStaticLibrary(.{
    //     .name = "master",
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    // b.installArtifact(lib);

    //https://ziglang.org/learn/build-system/#running-system-tools
    // https://github.com/ziglang/zig/blob/83e578a181e33eedd57666376dab371b7ae58d5b/lib/std/Build/Step/Compile.zig

    const assemble_step = b.addSystemCommand(&.{"nasm"});
    assemble_step.addArgs(&.{ "-g", "-f", "elf32", "-o" });
    const asm_obj = assemble_step.addOutputFileArg("boot.o");
    assemble_step.addFileArg(.{.path = "src/boot.asm"});

    // https://github.com/hjl-tools/x86-psABI/wiki/x86-64-psABI-1.0.pdf : a note about .code_model = .kernel
    const exe = b.addExecutable(.{
        .name = "coolos.bin",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });
    exe.linker_script = .{ .path = "src/linker.ld" };
    exe.addSystemIncludePath(.{.path = "src/third-party/"});

    exe.addObjectFile(asm_obj); // use output of assembing the boot assembly.

    const cp_file_step = b.addSystemCommand(&.{"cp"});
    cp_file_step.addArtifactArg(exe);
    cp_file_step.addArg("isodir/boot");

    const bake_iso = b.addSystemCommand(&.{"grub-mkrescue"});
    bake_iso.addArg("-o");
    const img_path = bake_iso.addOutputFileArg("coolos.img");
    bake_iso.addArg("isodir");
    bake_iso.step.dependOn(&cp_file_step.step);


    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.getInstallStep().*.dependOn(&bake_iso.step);
    const install_iso = b.addInstallFileWithDir(img_path, .prefix, "bin/coolos.img");
    install_iso.step.dependOn(&bake_iso.step);
    b.getInstallStep().dependOn(&install_iso.step);
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    // const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    // run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}

const std = @import("std");
const Target = @import("std").Target;
const Feature = @import("std").Target.Cpu.Feature;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {

    const features = Target.x86.Feature;

    var disabled_features = Feature.Set.empty;
    var enabled_features = Feature.Set.empty;

    // Yoinked from the Zig Bare Bones guide. One of these is needed to not
    //  allow floating points.
    // Later, I'll want to initialize the floating point stuff, but until then, no.
    // Without these, std.log.debug wants floats.
    disabled_features.addFeature(@intFromEnum(features.mmx));
    disabled_features.addFeature(@intFromEnum(features.sse));
    disabled_features.addFeature(@intFromEnum(features.sse2));
    disabled_features.addFeature(@intFromEnum(features.avx));
    disabled_features.addFeature(@intFromEnum(features.avx2));
    enabled_features.addFeature(@intFromEnum(features.soft_float));


    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .cpu_features_add = enabled_features,
        .cpu_features_sub = disabled_features
    } });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug
    }); // defaults to debug


    //https://ziglang.org/learn/build-system/#running-system-tools
    // https://github.com/ziglang/zig/blob/83e578a181e33eedd57666376dab371b7ae58d5b/lib/std/Build/Step/Compile.zig

    const assemble_step = b.addSystemCommand(&.{"nasm"});
    assemble_step.addArgs(&.{ "-g", "-f", "elf32", "-o" });
    const asm_obj = assemble_step.addOutputFileArg("boot.o");
    assemble_step.addFileArg(b.path("src/boot.asm"));

    // https://github.com/hjl-tools/x86-psABI/wiki/x86-64-psABI-1.0.pdf : a note about .code_model = .kernel
    const exe = b.addExecutable(.{
        .name = "coolos.bin",
        .root_source_file = b.path("src/main.zig" ),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });

    // Import the Zig pretty printing library from the build.zig.zon. Provides a way to print any struct. Nice.
    const pretty = b.dependency("pretty", .{.target=target, .optimize=optimize});
    exe.root_module.addImport("pretty", pretty.module("pretty"));

    exe.linker_script = b.path("src/linker.ld" );
    exe.addSystemIncludePath(b.path( "src/third-party/"));

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

}

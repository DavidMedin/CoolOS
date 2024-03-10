= CoolOS, A Cool Operating System.


# Zig Info:
current Zig version : https://ziglang.org/builds/zig-linux-x86_64-0.12.0-dev.3192+e2cbbd0c2.tar.xz\
current Zls version : commit ac60c30661cb4c371106c330d4a851fbd61c4d9e [tree](https://github.com/zigtools/zls/tree/ac60c30661cb4c371106c330d4a851fbd61c4d9e)\
The `zig` tools should be installed in a file system like this:
- `zig-tools`
    - `zig-linux` - just a renamed zig prebuilt, like extracted from the `zig-linux...tar.xz` above.
    - `zls` - a cloned, checkout out, and built `zls` repo.

These file will not be included in git.

# nix Things
BTW, by the end of making this commit, I have temperarily abandoned Nix. It was just not behaving with pre-built nix and zls. So I'm just downloading and building them separelty.

Use `just` to run, build, or debug. `just` uses `nix` (which uses `make`) to build.

### Ok, an attempt to use Nix.
there is a `nix` folder that contains some auto generated code on how to get the version of nix and packages we are using. Use those for reproducability.

### Using Nix and Zig
Used [zig2nix](https://github.com/Cloudef/zig2nix) to initialize the project. May need to run again to get new master.\
`nix --extra-experimental-features 'nix-command flakes' flake init -t github:Cloudef/zig2nix#master`.\
`nix run .`

Warning!\
If you ever update ZLS, you need to download that commit's `build.zig.zon` file run `zon2nix build.zig.zon > deps.nix` on it. This will update nix to be not stupid. Sorry, this is stupid.

# TODO:
[] Reimplement in Zig.
[] Use [Scalable Screen Font](https://wiki.osdev.org/Scalable_Screen_Font).
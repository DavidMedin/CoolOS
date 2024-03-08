= CoolOS, A Cool Operating System.

Use `just` to run, build, or debug. `just` uses `nix` (which uses `make`) to build.

### Ok, an attempt to use Nix.
there is a `nix` folder that contains some auto generated code on how to get the version of nix and packages we are using. Use those for reproducability.

# Using Nix and Zig
Used [zig2nix](https://github.com/Cloudef/zig2nix) to initialize the project. May need to run again to get new master.\
`nix --extra-experimental-features 'nix-command flakes' flake init -t github:Cloudef/zig2nix#master`.\
`nix run .`


Warning!\
If you ever update ZLS, you need to download that commit's `build.zig.zon` file run `zon2nix build.zig.zon > deps.nix` on it. This will update nix to be not stupid. Sorry, this is stupid.


# TODO:
[] Reimplement in Zig.
[] Use [Scalable Screen Font](https://wiki.osdev.org/Scalable_Screen_Font).
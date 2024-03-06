= CoolOs, A cool operating system.

The `i686-elf` cross-compiler (binutils & gcc) are at `/home/david/opt/cross/`.\
Make sure `/home/david/opt/cross/bin` is in your `PATH`.
Ok maybe not.

Use `just` to run, build, or debug. `just` uses `make` to build.

### Ok, an attempt to use Nix.
there is a `nix` folder that contains some auto generated code on how to get the version of nix and packages we are using. Use those for reproducability.

To build the project:
```bash
nix-build
```
and it should build. Nice.
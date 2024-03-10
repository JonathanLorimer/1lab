{ # Is this a nix-shell invocation?
  inNixShell ? false
  # Do we want the full Agda package for interactive use? Set to false in CI
, interactive ? true
, system ? builtins.currentSystem
}:
let
  pkgs = import ./support/nix/nixpkgs.nix { inherit system; };
in
  (import ./mk1lab.nix) {
    inherit interactive system;
    name = "1lab";
    src = if inNixShell then null else
      with pkgs.nix-gitignore; gitignoreFilterSourcePure (_: _: true) [
        # Keep .git around for extracting page authors
        (compileRecursiveGitignore ./.)
        ".github"
      ] ./.;
  }

{ system
, interactive
}:
let
  pkgs = import ./support/nix/nixpkgs.nix { inherit system; };
  lib = pkgs.lib;
in rec {
  inherit pkgs;

  agdaLib = mkDerivation:
    mkDerivation {
      pname = "1lab";
      version = "1.0.0";
      src = ./.;
      libraryName = "1lab";
      libraryFile = "1lab.agda-lib";
      everythingFile = "src/index.lagda.md";
      meta = with pkgs.lib; {
        description =
          "A formalised, cross-linked reference resource for mathematics done in Homotopy Type Theory ";
        homepage = src.meta.homepage;
        license = licenses.agpl3;
        platforms = platforms.unix;
      };
    };

  our-ghc = pkgs.labHaskellPackages.ghcWithPackages (ps: with ps; ([
    shake directory tagsoup
    text containers uri-encode
    process aeson Agda pandoc SHA
    fsnotify
  ] ++ (if interactive then [ haskell-language-server ] else [])));

  shakefile = pkgs.callPackage ./support/nix/build-shake.nix {
    inherit our-ghc;
    name = "1lab-shake";
    main = "Main.hs";
  };

  our-texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      collection-basic
      collection-latex
      xcolor
      preview
      pgf tikz-cd braids
      mathpazo
      varwidth xkeyval standalone;
  };

  sort-imports = let
    script = builtins.readFile support/sort-imports.hs;
    # Extract the list of dependencies from the stack shebang comment.
    deps = lib.concatLists (lib.filter (x: x != null)
      (map (builtins.match ".*--package +([^[:space:]]*).*")
        (lib.splitString "\n" script)));
  in pkgs.writers.writeHaskellBin "sort-imports" {
    ghc = pkgs.labHaskellPackages.ghc;
    libraries = lib.attrVals deps pkgs.labHaskellPackages;
  } script;

  deps = with pkgs; [
    # For driving the compilation:
    shakefile

    # For building the text and maths:
    gitMinimal nodePackages.sass

    # For building diagrams:
    poppler_utils our-texlive
  ] ++ (if interactive then [
    our-ghc
    sort-imports
  ] else [
    labHaskellPackages.Agda.data
    labHaskellPackages.pandoc.data
  ]);
}

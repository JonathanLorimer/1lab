{ name
, src
, system
, interactive
}:
let
  buildDeps = import ./buildDeps.nix { inherit system interactive; };
in with buildDeps;
  pkgs.stdenv.mkDerivation {
    inherit name src;

    nativeBuildInputs = deps;

    shellHook = ''
      export out=_build/site
    '';

    LANG = "C.UTF-8";
    buildPhase = ''
      1lab-shake all -j
    '';

    installPhase = ''
      # Copy our build artifacts
      mkdir -p $out
      cp -Lrvf _build/html/* $out

      # Copy KaTeX CSS and fonts
      mkdir -p $out/css
      cp -Lrvf --no-preserve=mode ${pkgs.nodePackages.katex}/lib/node_modules/katex/dist/{katex.min.css,fonts} $out/css/
      mkdir -p $out/static/ttf
      cp -Lrvf --no-preserve=mode ${pkgs.julia-mono}/share/fonts/truetype/JuliaMono-Regular.ttf $out/static/ttf/julia-mono.ttf
    '';

    passthru = {
      inherit deps shakefile sort-imports;
      texlive = our-texlive;
      ghc = our-ghc;
    };
  }

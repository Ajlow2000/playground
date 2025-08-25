{
  description = "OCaml Hello World with Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_1;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ocamlPackages.ocaml
            ocamlPackages.dune_3
            ocamlPackages.findlib
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
          ];

          shellHook = ''
            echo "OCaml development environment loaded!"
            echo "OCaml version: $(ocaml -version)"
          '';
        };

        packages.default = ocamlPackages.buildDunePackage {
          pname = "hello-world";
          version = "0.1.0";
          
          src = ./.;
          
          buildInputs = with ocamlPackages; [
            dune_3
          ];
        };
      }
    );
}

{
  description = "Haskell Hello World with Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          haskellPackages = pkgs.haskellPackages;
          packageName = "hello-world";
        in
        {
          default = haskellPackages.callCabal2nix packageName ./. { };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          haskellPackages = pkgs.haskellPackages;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with haskellPackages; [
              ghc
              cabal-install
              haskell-language-server
              hlint
              ormolu # code formatter
            ];

            shellHook = ''
              echo "Haskell development environment"
              echo "GHC version: $(ghc --version)"
              echo "Cabal version: $(cabal --version)"
              echo "HLS available for LSP support"
              echo ""
              echo "Build commands:"
              echo "  cabal build        - Build the project"
              echo "  cabal run hello-world - Build and run the executable"
              echo "  cabal clean        - Clean build artifacts"
            '';
          };
        }
      );
    };
}


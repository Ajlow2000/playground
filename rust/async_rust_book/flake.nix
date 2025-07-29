{
    inputs = {
        nixpkgs.url = "nixpkgs";
        flake-utils.url = "github:numtide/flake-utils";
    };
    outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
        let 
            pkgs = nixpkgs.legacyPackages.${system}; 

            basicBuildDependencies = with pkgs; [
                cargo
                rustc
                rustPlatform.bindgenHook
            ];

            developerTooling = with pkgs; [
                nil             # Nix LSP
                marksman        # MD LSP
                rust-analyzer   # Rust LSP
                rustfmt         # Rust Formatting -- might install from rust-toolchain.toml instead
                clippy
            ];

        in { 
            devShells.default = pkgs.mkShell {
                packages = basicBuildDependencies ++ developerTooling;
                shellHook = '''';
            };
        }
    );
}

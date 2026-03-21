{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        rust-overlay.url = "github:oxalica/rust-overlay";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, ... }: with inputs;
        let
           forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.unix;
           nixpkgsFor = forAllSystems (system: import nixpkgs {
                inherit system;
                config = { };
                overlays = [ rust-overlay.overlays.default ];
            });

        in {
            devShells = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.mkShell {
                        packages = with pkgs; [
                            (rust-bin.stable.latest.default.override {
                                targets = [ "riscv32imac-unknown-none-elf" ];
                            })
                            rust-analyzer
                            espflash
                        ];
                    };
                }
            );
       };
}

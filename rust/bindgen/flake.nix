{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = inputs@{ self, ... }: with inputs;
        let
           forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.unix;
           nixpkgsFor = forAllSystems (system: import nixpkgs {
                inherit system;
                config = { };
            });
            cargoToml = nixpkgs.lib.importTOML ./Cargo.toml;

        in {
            packages = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.rustPlatform.buildRustPackage {
                        pname = cargoToml.package.name;
                        version = cargoToml.package.version;
                        src = ./.;
                        cargoHash = "sha256-EfLfPCCjy7q1sshS2/J4SGsacRtAbYVi7OOvL4UBQzw=";
                    };
                }
            );
            checks = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.rustPlatform.buildRustPackage {
                        pname = cargoToml.package.name + "-tests";
                        version = cargoToml.package.version;
                        src = ./.;
                        cargoHash = "sha256-EfLfPCCjy7q1sshS2/J4SGsacRtAbYVi7OOvL4UBQzw=";
                        checkPhase = ''
                            cargo test
                        '';
                        installPhase = ''
                            touch $out
                        '';
                    };
                }
            );
            apps = forAllSystems (system: {
                default = {
                    type = "app";
                    program = "${self.packages.${system}.default}/bin/${cargoToml.package.name}";
                };
            });
            devShells = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.mkShell {
                        packages = with pkgs; [
                            rustc
                            cargo
                            rust-analyzer
                            libclang
                            rustPlatform.bindgenHook
                        ];
                    };
                }
            );
       };
}

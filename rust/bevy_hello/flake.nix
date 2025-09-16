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
            
            commonNativeBuildInputs = pkgs: with pkgs; [
                pkg-config
            ];
            commonBuildInputs = pkgs: with pkgs; [
                udev 
                alsa-lib-with-plugins 
                vulkan-loader
                xorg.libX11 
                xorg.libXcursor 
                xorg.libXi 
                xorg.libXrandr
                libxkbcommon
                wayland
            ];
        in {
            packages = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.rustPlatform.buildRustPackage {
                        pname = cargoToml.package.name;
                        version = cargoToml.package.version;
                        src = ./.;
                        cargoHash = "sha256-mx81WnxaKGZHr18JC7hg1uGcWlVlDrc7XUODAptPrlE=";
                        nativeBuildInputs = commonNativeBuildInputs pkgs;
                        buildInputs = commonBuildInputs pkgs;
                    };
                }
            );
            checks = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.rustPlatform.buildRustPackage {
                        pname = cargoToml.package.name + "-tests";
                        version = cargoToml.package.version;
                        src = ./.;
                        cargoHash = "sha256-mx81WnxaKGZHr18JC7hg1uGcWlVlDrc7XUODAptPrlE=";
                        nativeBuildInputs = commonNativeBuildInputs pkgs;
                        buildInputs = commonBuildInputs pkgs;
                        checkPhase = ''
                            cargo test
                        '';
                        installPhase = ''
                            touch $out
                        '';
                    };
                    # integration-test = import ./tests/integration.nix { inherit pkgs self cargoToml; };
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
                        ] ++ (commonNativeBuildInputs pkgs) ++ (commonBuildInputs pkgs);
                    };
                }
            );
       };
}

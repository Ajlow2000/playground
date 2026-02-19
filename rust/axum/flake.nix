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
                        cargoHash = "sha256-csMhUHHzWaQEOC8LkkZGaQ53G5SPxmUF5eJb30yAZgM=";
                    };
                }
            );
            checks = forAllSystems (system:
                let pkgs = nixpkgsFor."${system}"; in {
                    default = pkgs.rustPlatform.buildRustPackage {
                        pname = cargoToml.package.name + "-tests";
                        version = cargoToml.package.version;
                        src = ./.;
                        cargoHash = "sha256-csMhUHHzWaQEOC8LkkZGaQ53G5SPxmUF5eJb30yAZgM=";
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
                            postgresql
                        ];
                        shellHook = ''
                            export PGDATA="$PWD/.pg_data"
                            export DATABASE_URL="postgres://postgres:password@localhost"

                            if [ ! -d "$PGDATA" ]; then
                                initdb --auth=md5 --username=postgres --pwfile=<(echo "password")
                            fi

                            if ! pg_ctl status > /dev/null 2>&1; then
                                pg_ctl start -W -l "$PGDATA/pg.log" -o "-k /tmp"
                            fi

                            echo ""
                            echo "Postgres is running. Stop with: pg_ctl stop"
                            echo ""
                            echo "Usage:"
                            echo "  Run the server:    cargo run"
                            echo "  Create a note:     curl -X POST http://localhost:3000/notes -H 'Content-Type: application/json' -d '{\"content\": \"my note\"}'"
                            echo "  List all notes:    curl http://localhost:3000/notes"
                            echo "  Postgres shell:    psql -U postgres -h /tmp"
                            echo ""
                        '';
                    };
                }
            );
       };
}

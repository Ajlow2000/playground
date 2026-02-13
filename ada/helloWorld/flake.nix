{
  description = "Hello World in Ada";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "hello-world-ada";
          src = ./.;
          nativeBuildInputs = [ pkgs.gnat pkgs.gprbuild ];
          buildPhase = ''
            gprbuild -P hello_world.gpr
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp bin/hello $out/bin/
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/hello";
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.gnat pkgs.gprbuild ];
        };
      });
}

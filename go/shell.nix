{ pkgs ? (
    let
      inherit (builtins) fetchTree fromJSON readFile;
      inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs gomod2nix;
    in
    import (fetchTree nixpkgs.locked) {
      overlays = [
        (import "${fetchTree gomod2nix.locked}/overlay.nix")
      ];
    }
  )
, mkGoEnv ? pkgs.mkGoEnv
, gomod2nix ? pkgs.gomod2nix
}:

let
  goEnv = mkGoEnv { pwd = ./.; };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    gopls
    gotools
    go-tools
    cobra-cli
    # gomod2nix.packages.${system}.default
    gomod2nix
  ];
  packages = [
    goEnv
    gomod2nix
  ];
  shellHook = ''
  echo "Development Environment Loaded."
  echo ""
  echo "    To build and run this project with errors type 'go run main.go'."
  echo "    To test this project in it's deployment environment type 'nix run' or 'nix run . -- [args]'."
  echo "    If you added new project dependencies (ie, 'go get <url>'), run 'gomod2nix generate' and then the above nix run command"
  '';
}

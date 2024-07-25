{
  description = "C/C++ environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
    utils.lib.eachDefaultSystem (
      system:
      let
        p = import nixpkgs { inherit system; };
        llvm = p.llvmPackages_latest;
     in
      {
        devShell = p.mkShell.override { stdenv = p.clangStdenv; } rec {
          packages = with p; [
            # builder
            gcc
            just
            zig

            # debugger
            llvm.lldb
            gdb

            # fix headers not found
            clang-tools

            # LSP and compiler
            llvm.libstdcxxClang

            # other tools
            llvm.libllvm
            valgrind
            nil
            zls

            # libs
            glm
            SDL2
            SDL2_gfx
          ];
          name = "C";
        };
      }
    );
}


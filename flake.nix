{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      devShells.default = with pkgs;
        mkShell {
          packages = with pkgs; [
            zig
            clang-tools
            zls
          ];
          shellHook = ''
            export CC="zig c++"
            export CPLUS_INCLUDE_PATH="./zig-out/include"
          '';
        };
    });
}

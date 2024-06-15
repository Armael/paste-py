{
  description = "Paste-py";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, poetry2nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # create a custom "mkPoetryApplication" API function that under the hood uses
      # the packages and versions (python3, poetry etc.) from our pinned nixpkgs above:
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
      myPythonApp = mkPoetryApplication { projectDir = ./.; };
    in
    {
      apps.${system}.default = {
        type = "app";
        program = "${myPythonApp}/bin/paste-py";
      };
    };
}

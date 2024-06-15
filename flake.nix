{
  description = "Paste-py";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

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
      packages.${system}.default = myPythonApp;
    }
    // rec {
      nixosModules.paste-py = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.custom.paste-py;
        in
        {
          options.custom.paste-py = {
            enable = mkEnableOption (lib.mdDoc "paste-py: pastebin web service");
          };

          config = mkIf cfg.enable {
            systemd.services.paste-py =
              let
                pkg = self.packages.${system}.default;
              in {
                description = "paste-py: pastebin web service";
                after = [ "network.target" "network-online.target" ];
                wants = [ "network.target" "network-online.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  ExecStart = "${pkg}/bin/paste-py";
                  StateDirectory = "paste-py";
                  StateDirectoryMode = 0700;
                  WorkingDirectory = "/var/lib/paste-py";
                  DynamicUser = true;
                };
              };
          };
        };

      nixosModules.default = nixosModules.paste-py;
    };
}

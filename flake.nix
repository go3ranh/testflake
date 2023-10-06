{
  description = "webscraper in bash";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = rec {
          scraper = pkgs.writeShellScriptBin "scrape" ''
                        if [ $# -ne 2 ]; then
                          echo "please provide a url and a number of passes"
                          exit 1
                        fi
                        echo "${pkgs.htmlq.outPath}/bin/htmlq"
                        urls=$(curl -s $1 | ${pkgs.htmlq.outPath}/bin/htmlq --attribute href a)
                        for url in $urls; do
            				echo $url | awk -F':' '$1=="https"{print $2}' | grep "//" >/dev/null
            				if [ $? -eq 0 ]; then
                                curl -s $url | ${pkgs.htmlq.outPath}/bin/htmlq --attribute href a
            				fi
                        done
          '';
          gcodepy = pkgs.python3Packages.buildPythonPackage {
            pname = "gcodepy";
            version = "0.1.1";
            patches = [
              ./0012-setup-file.patch # exposes $WALLABAG_DATA
            ];
            src = pkgs.python3Packages.fetchPypi {
              pname = "gcodepy";
              version = "0.1.1";
              sha256 = "sha256-GlQf+BDlll75Dqs2sqWVboeA7ODiWzcklpLAU4i9NwU=";
            };
          };
          dreide = pkgs.python3Packages.buildPythonApplication rec {
            pname = "dreide";
            version = "0.0.1";
            buildInputs = [ gcodepy ];
            src = ./src;
            installPhase = ''
              mkdir -p $out/bin
              ln -s $src/main.py $out/bin/${pname}
              chmod +x $src/main.py $out/bin/${pname}
            '';
          };
        };
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [

              (pkgs.python3.withPackages (ps: [ packages.gcodepy ]))
            ];
          };
        };
        formatter = pkgs.nixpkgs-fmt;
      });
}

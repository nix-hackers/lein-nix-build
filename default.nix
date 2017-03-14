args@
{ pkgs ? import <nixpkgs> {}
, buildMaven ? pkgs.buildMaven
, leiningen ? pkgs.leiningen
, jdk ? pkgs.jdk
, stdenv ? pkgs.stdenv
, project ? <project>
, uberjarName ? "*standalone.jar"
, buildPhase ? "lein uberjar"
, checkPhase ? "lein test"
, doCheck ? false
, ...
}:
let
  inherit (buildMaven (project + "/project-info.json")) repo build info;
  inherit (info.project) artifactId version;
in stdenv.mkDerivation (args // {
  name = "${artifactId}-${version}-standalone.jar";

  inherit (build) src;
  inherit version buildPhase checkPhase doCheck;

  buildInputs = [ leiningen ] ++ (args.buildInputs or []);

  nativeBuildInputs = [ pkgs.makeWrapper ] ++ (args.nativeBuildInputs or []);

  LEIN_OFFLINE = 1;

  configurePhase = ''
    mkdir -p home/.m2
    ln -s ${repo} home/.m2/repository
    ln -s ${jdk}/bin/java java
    wrapProgram java --add-flags -Duser.home=$PWD/home
    export LEIN_JAVA_CMD=$PWD/java
  '' + (args.configurePhase or "");

  installPhase = ''
    find . -name '${uberjarName}' -exec mv '{}' $out \;
  '';
})

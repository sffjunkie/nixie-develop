{
  lib,
  fetchurl,
  jre,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "trino-server";
  version = "440";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/io/trino/${pname}/${version}/${pname}-${version}.tar.gz";
    hash = "sha256-dwrG+p3/acx+wsYysrJ5uAJVY5jHolVh1tIKPtXxVyk=";
  };

  nativeBuildInputs = [jre];

  installPhase = ''
    mkdir -p $out
    cp -r {bin,lib,plugin} $out
  '';

  meta = with lib; {
    description = "Apache Trino";
    homepage = "https://github.com/trinodb/trino";
    license = licenses.asl20;
    # maintainers = with maintainers; [  ];
  };
}

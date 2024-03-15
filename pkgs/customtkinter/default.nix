{
  lib,
  fetchFromGitHub,
  python3,
}:
python3.pkgs.buildPythonPackage rec {
  pname = "customtkinter";
  version = "5.2.2";

  src = fetchFromGitHub {
    owner = "TomSchimansky";
    repo = "CustomTkinter";
    rev = "v${version}";
    sha256 = "sha256-1g2wdXbUv5xNnpflFLXvU39s16kmwvuegKWd91E3qm4=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    darkdetect
    packaging
    typing-extensions
  ];

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/TomSchimansky/CustomTkinter/";
    description = "Custom Python tkinter UI library.";
    license = licenses.mit;
    # maintainers = with maintainers; [thomasjm];
  };
}

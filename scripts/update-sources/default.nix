{
  writeShellApplication,
  gh,
  niv,
  pythonEnv,
}:
writeShellApplication {
  name = "update-sources";
  runtimeInputs = [
    gh
    niv
    pythonEnv
  ];
  text = ''
    gh api repos/microsoft/vscode-js-debug/releases --jq '.[].tag_name' | python ${./update-sources.py}
  '';
}

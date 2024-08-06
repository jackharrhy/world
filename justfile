set windows-powershell

run:
  odin run .

build-linux:
  odin build .

build-windows:
  odin build . -subsystem:windows

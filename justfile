set shell := ["powershell", "-c"]

run:
  odin run .

build:
  odin build . -subsystem:windows
package world

import rl "vendor:raylib"

GameScreen :: enum {
	Loading,
	Game,
}

Client :: struct {
	id:    string,
	name:  cstring,
	color: rl.Color,
	x:     i32,
	y:     i32,
}

ClientsMessage :: struct {
	type:    string,
	clients: []Client,
}

ServerMessage :: union {
	ClientsMessage,
}

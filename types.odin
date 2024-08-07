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
	clients: []Client,
}

InitMessage :: struct {
	clients: []Client,
	me:      Client,
}

ServerMessage :: union {
	ClientsMessage,
	InitMessage,
}

MeMessage :: struct {
	me: Client,
}

ClientMessage :: union {
	MeMessage,
}

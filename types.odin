package world

import rl "vendor:raylib"

Client :: struct {
	id:    string,
	name:  cstring,
	color: rl.Color,
	x:     i32,
	y:     i32,
}

ClientsMessage :: struct {
	type:    string,
	clients: [dynamic]Client,
}

ServerMessage :: union {
	ClientsMessage,
}

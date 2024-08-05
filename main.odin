package world

import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:net"
import "core:os"
import "core:strings"
import "core:sync"
import rl "vendor:raylib"

SERVER_ADDRESS :: "localhost:6688"
CLIENT_SIZE :: 30

clients_mutex: sync.Mutex
clients := [dynamic]Client{}

main :: proc() {
	context.logger = log.create_console_logger(.Debug)

	setup_listener()

	rl.InitWindow(512, 512, "world")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	font := rl.LoadFont("resources/fonts/alpha_beta.png")
	defer rl.UnloadFont(font)

	for !rl.WindowShouldClose() {
		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.RAYWHITE)

			{
				sync.lock(&clients_mutex)
				defer sync.unlock(&clients_mutex)
				for client in clients {
					rl.DrawRectangle(client.x, client.y, CLIENT_SIZE, CLIENT_SIZE, client.color)
				}
			}

			rl.DrawFPS(10, 10)
		}
	}
}

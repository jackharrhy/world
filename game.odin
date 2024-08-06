package world

import "core:sync"
import rl "vendor:raylib"

handle_game_loop :: proc() {
	sync.lock(&game_screen_mutex)
	defer sync.unlock(&game_screen_mutex)

	switch game_screen {
	case GameScreen.Loading:
		handle_loading_screen()
	case GameScreen.Game:
		handle_game_screen()
	case:
		unreachable()
	}
}

handle_loading_screen :: proc() {
	{
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawText("Loading...", 10, 10, 20, rl.MAROON)
	}
}

handle_game_screen :: proc() {
	sync.lock(&me_mutex)
	defer sync.unlock(&me_mutex)

	if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
		me.x += 2.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
		me.x -= 2.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.UP) {
		me.y -= 2.0
	}

	if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
		me.y += 2.0
	}

	{
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawRectangle(me.x, me.y, CLIENT_SIZE, CLIENT_SIZE, me.color)

		{
			sync.lock(&clients_mutex)
			defer sync.unlock(&clients_mutex)
			for client in clients {
				rl.DrawRectangle(client.x, client.y, CLIENT_SIZE, CLIENT_SIZE, client.color)
			}
		}

		// rl.DrawFPS(10, 10)
	}
}

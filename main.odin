package world

import "core:log"
import "core:sync"
import rl "vendor:raylib"

SERVER_ADDRESS :: "localhost:6688"
CLIENT_SIZE :: 30

// game_screen: GameScreen = GameScreen.Loading
game_screen: GameScreen = GameScreen.Game
game_screen_mutex: sync.Mutex

me: Client
me_mutex: sync.Mutex

clients: []Client
clients_mutex: sync.Mutex

main :: proc() {
	context.logger = log.create_console_logger(.Debug)

	setup_listener()

	rl.InitWindow(512, 512, "world")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	font := rl.LoadFont("resources/fonts/alpha_beta.png")
	defer rl.UnloadFont(font)

	for !rl.WindowShouldClose() {
		handle_game_loop()
	}
}

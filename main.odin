package world

import "core:log"
import "core:sync"
import "core:sync/chan"
import "core:time"
import rl "vendor:raylib"

SERVER_ADDRESS :: "localhost:6688"
CLIENT_SIZE :: 30
UPDATE_INTERVAL :: time.Millisecond * 200

// TODO put all of these into some sort of global
// game context struct that is passed by reference
// to all functions that need it rather than using
// global variables

game_screen: GameScreen = GameScreen.Loading
game_screen_mutex: sync.Mutex

me: Client
me_mutex: sync.Mutex

clients: []Client
clients_mutex: sync.Mutex

client_messages: chan.Chan(ClientMessage)

main :: proc() {
	context.logger = log.create_console_logger(.Debug)
	rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR)

	setup_err := setup_network()

	if setup_err != nil {
		log.error("Failed to setup network: %s", setup_err)
		return
	}

	rl.InitWindow(512, 512, "world")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	font := rl.LoadFont("resources/fonts/alpha_beta.png")
	defer rl.UnloadFont(font)

	for !rl.WindowShouldClose() {
		handle_game_loop()
	}
}

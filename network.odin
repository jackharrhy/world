package world

import "core:encoding/json"
import "core:log"
import "core:net"
import "core:os"
import "core:sync"
import "core:sync/chan"
import "core:thread"
import "core:time"

MessageError :: enum {
	None,
	UnknownType,
}

NetworkError :: union #shared_nil {
	net.Network_Error,
	json.Error,
	MessageError,
}

setup_socket :: proc() -> (socket: net.TCP_Socket, err: net.Network_Error) {
	socket, err = net.dial_tcp_from_hostname_and_port_string(SERVER_ADDRESS)

	if err != nil {
		log.errorf("Failed to connect to server: %s\n", err)
		return
	}

	return socket, nil
}

get_bytes_from_socket :: proc(
	socket: net.TCP_Socket,
) -> (
	bytes: [dynamic]byte,
	done: bool,
	err: net.Network_Error,
) {
	for {
		buffer: [16]byte
		n, err := net.recv_tcp(socket, buffer[:])

		if err == net.TCP_Recv_Error.Timeout {
			continue
		} else if err != nil {
			log.errorf("Failed to get bytes from socket: %s\n", err)
			done = true
			return
		}

		if n == 0 {
			done = true
			return
		}

		append(&bytes, ..buffer[:n])

		if buffer[n - 1] == '\n' {
			pop(&bytes)
			break
		}
	}

	return
}

parse_message :: proc(bytes: [dynamic]byte) -> (message: ServerMessage, err: NetworkError) {
	json_data: json.Value
	json_data, err = json.parse(bytes[:])

	if err != nil {
		log.errorf("Failed to parse JSON: %s\n", err)
		return
	}

	root := json_data.(json.Object)

	type := root["type"].(json.String)

	switch type {
	case "clients":
		message: ClientsMessage
		json.unmarshal(bytes[:], &message)
		return message, nil
	case "init":
		message: InitMessage
		json.unmarshal(bytes[:], &message)
		return message, nil
	case:
		log.errorf("Unknown message type: %s\n", type)
		err = MessageError.UnknownType
		return
	}
}

recieve_message :: proc(
	socket: net.TCP_Socket,
) -> (
	message: ServerMessage,
	done: bool,
	err: NetworkError,
) {
	bytes: [dynamic]byte
	defer delete(bytes)

	socket_err: net.Network_Error
	bytes, done, err = get_bytes_from_socket(socket)

	if done || err != nil {
		log.errorf("Failed to get bytes from socket: %s\n", socket_err)
		return
	}

	message, err = parse_message(bytes)

	return
}

update_clients :: proc(new_clients: []Client) {
	sync.lock(&clients_mutex)
	defer sync.unlock(&clients_mutex)
	delete(clients)
	clients = new_clients
}

update_me :: proc(new_me: Client) {
	sync.lock(&me_mutex)
	defer sync.unlock(&me_mutex)
	me = new_me
}

update_game_screen :: proc(new_screen: GameScreen) {
	sync.lock(&game_screen_mutex)
	defer sync.unlock(&game_screen_mutex)
	game_screen = new_screen
}

listener :: proc(socket: net.TCP_Socket) {
	log.debug("Client recive loop started")

	for {
		message, done, err := recieve_message(socket)

		if done || err != nil {
			break
		}

		log.debug("Recived message: %s", message)

		switch m in message {
		case ClientsMessage:
			update_clients(m.clients)
		case InitMessage:
			update_clients(m.clients)
			update_me(m.me)
			update_game_screen(GameScreen.Game)
		}
	}

	log.debug("Client recive loop ended")
}

sender :: proc(socket: net.TCP_Socket) {
	log.debug("Client send loop started")

	for {
		// TODO impl https://jakubtomsu.github.io/posts/input_in_fixed_timestep/
		time.sleep(UPDATE_INTERVAL)

		message: MeMessage
		message.type = "me"

		{
			sync.lock(&me_mutex)
			defer sync.unlock(&me_mutex)

			message.me = me
		}

		bytes, json_err := json.marshal(message)

		if json_err != nil {
			log.errorf("Failed to marshal message: %s\n", json_err)
			break
		}

		_, net_err := net.send_tcp(socket, bytes)

		if net_err != nil {
			log.errorf("Failed to send message: %s\n", net_err)
			break
		}
	}

	log.debug("Client send loop ended")
}

setup_network :: proc() -> (err: net.Network_Error) {
	socket, failed := setup_socket()

	if failed != nil {
		err = failed
		return
	}

	thread.create_and_start_with_poly_data(socket, proc(socket: net.TCP_Socket) {
		context.logger = log.create_console_logger(.Debug)
		listener(socket)
	})

	thread.create_and_start_with_poly_data(socket, proc(socket: net.TCP_Socket) {
		context.logger = log.create_console_logger(.Debug)
		sender(socket)
	})

	return
}

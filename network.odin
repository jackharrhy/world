package world

import "core:encoding/json"
import "core:log"
import "core:net"
import "core:os"
import "core:sync"
import "core:thread"

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

		if n == 0 {
			done = true
			return
		}
		if err == net.TCP_Recv_Error.Timeout {
			continue
		} else if err != nil {
			log.errorf("Failed to get bytes from socket: %s\n", err)
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

setup_listener :: proc() {
	client_recive_loop: thread.Thread_Proc : proc(t: ^thread.Thread) {
		context.logger = log.create_console_logger(.Debug)

		log.info("Client recive loop started")
		socket, failed := setup_socket()

		if failed != nil {
			// TODO handle without exiting everything
			// maybe way to send a message to the main thread, which
			// will affect rendering, and then retry with some level
			// of backoff?
			os.exit(1)
		}

		for {
			message, done, err := recieve_message(socket)

			if done || err != nil {
				break
			}

			log.info("Recived message: %s", message)

			switch m in message {
			case ClientsMessage:
				{
					sync.lock(&clients_mutex)
					defer sync.unlock(&clients_mutex)
					delete(clients)
					clients = m.clients
				}
			}
		}

		log.warn("Client recive loop ended")
	}

	log.info("Starting client recive loop")

	recieve_thread := thread.create(client_recive_loop)
	thread.start(recieve_thread)
}

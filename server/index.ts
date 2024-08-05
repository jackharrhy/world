import type { Socket } from "bun";

const spaceSize = 512;

const hostname = "127.0.0.1";
const port = 6688;

crypto.randomUUID();

type SocketData = { id: string };

type Client = {
  id: string,
  color: [number, number, number, number],
  socket: Socket<SocketData>,
  x: number;
  y: number;
}

type ClientsMessage = {
  type: "clients",
  clients: Omit<Client, "socket">[];
}

const clients: Record<string, Client> = {};

const sendClients = (socket: Socket<SocketData>) => {
  const clientMessage: ClientsMessage = {
    type: "clients",
    clients: Object.values(clients).map(({ id, color, x, y }) => ({ id, color, x, y })),
  };

  socket.write(`${JSON.stringify(clientMessage)}\n`);
}

setInterval(() => {
  Object.values(clients).forEach(({ socket }) => {
    sendClients(socket);
  });
}, 500);

Bun.listen<SocketData>({
  hostname,
  port,
  socket: {
    data(socket, data) {
      console.log(`socket data: ${socket.data.id} - ${data}`);
      socket.write(`you said: ${data}`);
    },
    open(socket) {
      const id = crypto.randomUUID();
      socket.data = { id };
      clients[id] = {
        id,
        color: [255, 0, 0, 255],
        socket,
        x: Math.floor(Math.random() * spaceSize),
        y: Math.floor(Math.random() * spaceSize)
      };
      console.log(`socket opened: ${id}`);
      sendClients(socket);
    },
    close(socket) {
      delete clients[socket.data.id];
      console.log(`socket closed: ${socket.data.id}`);
    },
    error(socket, error) {
      console.error(`socket error: ${socket.data.id} - ${error}`);
    },
  },
});

console.log(`server running on ${hostname}:${port} via tcp`);

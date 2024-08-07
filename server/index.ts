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

type InitMessage = {
  type: "init",
  me: Omit<Client, "socket">,
  clients: Omit<Client, "socket">[];
}

const clients: Record<string, Client> = {};

const createClientsMessage = (ignoreClient: Client): ClientsMessage => ({
  type: "clients",
  clients: Object.values(clients)
    .map(({ id, color, x, y }) => ({ id, color, x, y }))
    .filter(({ id }) => id !== ignoreClient.id),
});

const sendClients = (socket: Socket<SocketData>, me: Client) => {
  const clientMessage = createClientsMessage(me);
  socket.write(`${JSON.stringify(clientMessage)}\n`);
}

const sendInit = (socket: Socket<SocketData>, me: Client) => {
  const initMessage: InitMessage = {
    type: "init",
    me: { id: me.id, color: me.color, x: me.x, y: me.y },
    clients: Object.values(clients).map(({ id, color, x, y }) => ({ id, color, x, y })),
  };

  socket.write(`${JSON.stringify(initMessage)}\n`);
};

setInterval(() => {
  Object.values(clients).forEach(({ socket }) => {
    sendClients(socket, clients[socket.data.id]);
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
      const client = {
        id,
        color: [255, 0, 0, 255],
        socket,
        x: Math.floor(Math.random() * spaceSize),
        y: Math.floor(Math.random() * spaceSize)
      } satisfies Client;
      clients[id] = client;

      console.log(`socket opened: ${id}`);
      sendInit(socket, client);
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

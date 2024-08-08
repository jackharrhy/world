import type { Socket } from "bun";
import debugFactory from "debug";

debugFactory.enable("world:*");

const debug = debugFactory("world:index");

const updateRate = 1000 / 40;

const spaceSize = 512;

const hostname = "127.0.0.1";
const port = 6688;

crypto.randomUUID();

type SocketData = { id: string };

type Client = {
  id: string;
  color: [number, number, number, number];
  socket: Socket<SocketData>;
  x: number;
  y: number;
};

type ClientsMessage = {
  type: "clients";
  clients: Omit<Client, "socket">[];
};

type InitMessage = {
  type: "init";
  me: Omit<Client, "socket">;
  clients: Omit<Client, "socket">[];
};

type ServerMessage = ClientsMessage | InitMessage;

type MeMessage = {
  type: "me";
  me: Omit<Client, "socket">;
};

type ClientMessage = MeMessage;

const clients: Record<string, Client> = {};

const sendToSocket = (socket: Socket<SocketData>, message: object) => {
  debug(`sending to ${socket.data.id}: ${JSON.stringify(message)}`);
  socket.write(`${JSON.stringify(message)}\n`);
};

const createClientsMessage = (ignoreClient: Client): ClientsMessage => ({
  type: "clients",
  clients: Object.values(clients)
    .map(({ id, color, x, y }) => ({ id, color, x, y }))
    .filter(({ id }) => id !== ignoreClient.id),
});

const sendClients = (socket: Socket<SocketData>, me: Client) => {
  const clientMessage = createClientsMessage(me);
  sendToSocket(socket, clientMessage);
};

const sendInit = (socket: Socket<SocketData>, me: Client) => {
  const initMessage: InitMessage = {
    type: "init",
    me: { id: me.id, color: me.color, x: me.x, y: me.y },
    clients: Object.values(clients).map(({ id, color, x, y }) => ({
      id,
      color,
      x,
      y,
    })),
  };
  sendToSocket(socket, initMessage);
};

setInterval(() => {
  Object.values(clients).forEach(({ socket }) => {
    sendClients(socket, clients[socket.data.id]);
  });
}, updateRate);

Bun.listen<SocketData>({
  hostname,
  port,
  socket: {
    data(socket, data) {
      debug(`socket data: ${data}`);
      const message = JSON.parse(data.toString()) as ClientMessage;

      switch (message.type) {
        case "me": {
          const client = clients[socket.data.id];
          client.x = message.me.x;
          client.y = message.me.y;
          break;
        }
        default:
          console.error(`unknown message type: ${message.type}`);
          break;
      }
    },
    open(socket) {
      const id = crypto.randomUUID();
      socket.data = { id };
      const client = {
        id,
        color: [255, 0, 0, 255],
        socket,
        x: Math.floor(Math.random() * spaceSize),
        y: Math.floor(Math.random() * spaceSize),
      } satisfies Client;
      clients[id] = client;

      debug(`socket opened: ${id}`);
      sendInit(socket, client);
    },
    close(socket) {
      delete clients[socket.data.id];
      debug(`socket closed: ${socket.data.id}`);
    },
    error(socket, error) {
      debug(`socket error: ${socket.data.id} - ${error}`);
    },
  },
});

console.info(`server running on ${hostname}:${port} via tcp`);

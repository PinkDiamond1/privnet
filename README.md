# Private network of QAN Platform

You can play around with QAN's private network with EC crypto stack.
The bundled ```test.sh``` convenience script will help you out to get up and running quickly.

## How to use

### Start X nodes

The below example will:

- Check for a newer docker image and pull it
- Ensure that a dedicated QAN docker network exists
- Launch a QAN privnet bootstrap node on this network
- Create 5 QAN privnet nodes
- Connect above nodes to the network
- Start all nodes one-by-one

```sh
sh test.sh start 5
```

### Separate bootstrap node

All nodes are initialized by connecting them to the bootstrap node of the private network.

But what happens when it becomes unavailable? To simulate this scenario issue the following command:

```sh
sh test.sh separate
```

All nodes will renegotiate routing among each other and everything continues to work as expected.

### Stop test

Simply issue the following command:

```sh
sh test.sh stop
```

This will remove all launched nodes (including the bootstrap node if it was not separated) and the dedicated QAN docker network as well, so everything related to this test run is cleaned up properly.

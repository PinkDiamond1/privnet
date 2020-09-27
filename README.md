# Private network of QAN Platform

You can play around with QAN's private network with EC crypto stack.
The bundled ```test.sh``` convenience script will help you out to get up and running quickly.

## How to use

### Start X nodes locally

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

### Deploy using container orchestration


QAN supports deploying to major container orchestrators, such as Docker Swarm.

#### Deploy using Docker Swarm

To deploy a QAN private network to Docker Swarm, first ensure that:

- The machine is a docker swarm **manager** node.
- There is **at least one worker** node in your swarm cluster.

If above two conditions are satisfied, then you can proceed to deploy by entering the following:

```sh
bash test.sh deploy swarm
```

This will deploy the stack template defined in ```deploy/docker-swarm/stack.yml```.

#### Deploy using Kubernetes

To deploy a QAN private network to Kubernetes, first ensure that:

- You have ```kubectl``` installed locally

If above condition is met, then you can proceed to deploy by entering the following:

```sh
bash test.sh deploy kubernetes
```

This will deploy the kubernetes manifests defined in ```deploy/kubernetes/*.yaml```.

### Separate bootstrap node

All nodes are initialized by connecting them to the bootstrap node of the private network.

But what happens when it becomes unavailable? To simulate this scenario issue the following command:

```sh
sh test.sh separate
```

All nodes will renegotiate routing among each other and everything continues to work as expected.

### CLI Wallet examples

Simply issue the following command:

```sh
sh test.sh wallet
```

This will drop you in a REPL where you can unlock a wallet and execute certain functions.
1. When prompted for wallet name, simply enter "testwallet".
2. When prompted for password, simply hit the ```RETURN``` button (empty passphrase)
3. Execute ```print_address``` in the REPL to ensure the unlock was successful, it should print the address ```52c4ba9a2237cc9e03192cd448e8e5e9a17211dd```.

### Stop test

Simply issue the following command:

```sh
sh test.sh stop
```

This will remove all launched nodes (including the bootstrap node if it was not separated) and the dedicated QAN docker network as well, so everything related to this test run is cleaned up properly.

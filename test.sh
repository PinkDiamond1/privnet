#!/bin/bash

# DECLARE VARIABLES FOR SETUP
QAN_NETWORK=qan_privnet
QAN_IMAGE=qanplatform/privnet
NUMBER_OF_NODES=3

# IF DOCKER IS NOT EXECUTABLE
if [ ! -x $(which docker) ]; then

    # THROW EXECPTION
    echo "docker command is not executable, exiting!"
    exit 1
fi

# FUNCTION TO PROPERLY REMOVE CONTAINER
remove_container() {
    echo "Stopping container: " $1
    docker container stop $1 > /dev/null 2>&1
    echo "Stopped  container: " $1
    docker container rm $1 > /dev/null 2>&1
    echo "Removed  container: " $1
}

# IF START COMMAND REQUESTED AND 2nd PARAM PASSED AND IS A NUMBER
if [ "$1" == "start" ] && [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then

    # OVERRIDE DEFAULT NUMBER OF NODES
    NUMBER_OF_NODES=$2
fi

# COMMAND SELECTOR
case $1 in

    # DEPLOYMENT HELPERS
    'deploy')

        # CHECK IF ORCHESTRATOR SPECIFIED
        case $2 in

            # DOCKER SWARM
            'swarm')

                # IF DOCKER IS NOT EXECUTABLE
                if ! docker node ls > /dev/null 2>&1; then

                    # THROW EXECPTION
                    echo "docker swarm is not set up or this node is not a manager, exiting!"
                    exit 1
                fi

                # IF STACK FILE DOESN'T EXIST
                STACKFILE=$(pwd)"/deploy/docker-swarm/stack.yml"
                if [ ! -f $STACKFILE ]; then

                    # THROW EXECPTION
                    echo "docker stack descriptor not found, exiting!"
                    exit 1
                fi

                if docker stack deploy -c $STACKFILE "qan"; then
                    echo "deployed to docker swarm successfully!"
                fi
            ;;
        esac
    ;;

    # START TEST
    'start')

        # PULL UP-TO-DATE IMAGE
        docker pull $QAN_IMAGE

        # IF NETWORK DOES NOT EXIST YET
        if ! docker network inspect $QAN_NETWORK > /dev/null 2>&1; then

            # CREATE IT
            echo "Docker network does not exist yet, creating...";
            if ! docker network create --driver bridge $QAN_NETWORK > /dev/null 2>&1; then
                echo "Docker network $QAN_NETWORK could not be created, exiting."
                exit 1
            fi
            echo "Docker network '$QAN_NETWORK' created.";
        fi

        # IF THERE IS A BOOTSTRAP CONTAINER
        if docker container inspect "qan_node_bootstrap" > /dev/null 2>&1; then

            # STOP AND REMOVE IT, THERE MIGHT BE A NEW IMAGE FOR IT
            echo "Old bootstrap container 'qan_node_bootstrap' exists, removing..."
            remove_container "qan_node_bootstrap"
        fi

        # START BOOTSTRAP NODE (WITH POSSIBLY NEW IMAGE)
        docker container run --detach --name "qan_node_bootstrap" $QAN_IMAGE > /dev/null
        echo 'Started QAN bootstrap node'

        # CONNECT TO QAN DOCKER NETWORK
        docker network connect $QAN_NETWORK "qan_node_bootstrap"

        # WAIT FOR BOOTSTRAP NODE STARTUP
        echo 'Waiting for bootstrap node startup...'
        sleep 5

        # LAUNCH REQUIRED NUMBER OF NODES
        for ((i = 0 ; i < $NUMBER_OF_NODES ; i++)); do

            # DYNAMIC PORT FORWARDING FOR FIRST NODE
            PORTFORWARD="300$i:3000"

            # START NEW INSTANCES
            docker container create --name "qan_node_"$i \
                --network $QAN_NETWORK \
                --publish $PORTFORWARD --env BOOTSTRAP='nats://qan_node_bootstrap:6222' \
                $QAN_IMAGE > /dev/null 2>&1
            echo "Created   node qan_node_"$i "container"
        done

        # START DAEMON ON ALL NODES
        for ((i = 0 ; i < $NUMBER_OF_NODES ; i++)); do

            # START NEW INSTANCES
            docker container start "qan_node_"$i > /dev/null
            echo "Started node qan_node_"$i "container"
        done
    ;;

    # SEPARATE BOOTSTRAP NODE
    "separate")
        remove_container "qan_node_bootstrap"
        echo "bootstrap container stopped"
    ;;

    # LAUNCH INTERACTIVE WALLET
    "wallet")

        # IF THERE IS NO NODE0, WALLET CAN NOT CONNECT OVER RPC
        if ! docker container inspect "qan_node_0" > /dev/null 2>&1 ; then
            echo "wallet was unable to connect to node"
            exit 1
        fi

        # GET IP OF RPC
        RPC_IP=$(docker exec "qan_node_0" ip a | grep inet | grep -v 127 | awk '{print $2}' | cut -d"/" -f1)

        # RUN WALLET BINARY WHICH CONNECTS TO THE RPC IP ON PORT 3000
        docker run --rm -it --network $QAN_NETWORK \
            --entrypoint "/usr/bin/wallet_cli" \
            --name "qan_wallet" $QAN_IMAGE -r "http://"$RPC_IP":3000"
    ;;

    # STOP TEST
    'stop')

        for ((i = 0 ; i < 100 ; i++)); do

            # IF THERE IS A CONTAINER ALREADY RUNNING
            if ! docker container inspect "qan_node_"$i > /dev/null 2>&1 ; then
                break
            fi

            # IF THERE IS A CONTAINER ALREADY RUNNING
            if docker container inspect "qan_node_"$i > /dev/null 2>&1 ; then

                # STOP AND REMOVE IT
                remove_container "qan_node_"$i
            fi
        done

        # IF THERE IS A BOOTSTRAP CONTAINER
        if docker container inspect "qan_node_bootstrap" > /dev/null 2>&1; then

            # STOP AND REMOVE IT
            remove_container "qan_node_bootstrap"
        fi

        # IF THERE IS A WALLET CONTAINER
        if docker container inspect "qan_wallet" > /dev/null 2>&1; then

            # STOP AND REMOVE IT
            remove_container "qan_wallet"
        fi

        # REMOVE NETWORK AS WELL
        docker network rm $QAN_NETWORK > /dev/null 2>&1
    ;;

    # HELP
    *)
        echo 'Usage:'
        echo '========='

        echo 'START:'
        echo '    ./test.sh start $NUMBER_OF_NODES (default 3)'

        echo 'SEPARATE (kills bootnode):'
        echo '    ./test.sh separate'

        echo 'STOP:'
        echo '    ./test.sh stop'
    ;;
esac

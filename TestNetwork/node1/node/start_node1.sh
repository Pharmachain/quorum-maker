#!/bin/bash

function upcheck() {
    DOWN=true
    k=10
    while ${DOWN}; do
        sleep 1
        DOWN=false
        
        if [ ! -S "qdata/node1.ipc" ]; then
            echo "Node is not yet listening on node1.ipc" >> qdata/gethLogs/node1.log
            DOWN=true
        fi

        result=$(curl -s http://$CURRENT_NODE_IP:22002/upcheck)

        if [ ! "${result}" == "I'm up!" ]; then
            echo "Node is not yet listening on http" >> qdata/gethLogs/node1.log
            DOWN=true
        fi
    
        k=$((k - 1))
        if [ ${k} -le 0 ]; then
            echo "Constellation/Tessera is taking a long time to start.  Look at the Constellation/Tessera logs for help diagnosing the problem." >> qdata/gethLogs/node1.log
        fi
       
        sleep 5
    done
}

NETID=71677
RA_PORT=22003
R_PORT=22000
W_PORT=22001
NODE_MANAGER_PORT=22004
WS_PORT=22005
CURRENT_NODE_IP=10.50.0.2

tessera="java -jar /tessera/tessera-app.jar"

ENABLED_API="admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft"
GLOBAL_ARGS="--raft --nodiscover --gcmode=archive --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi $ENABLED_API --emitcheckpoints"

rm -f qdata/*lock.db

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_node1.log

constellation-node node1.conf >> qdata/constellationLogs/constellation_node1.log 2>&1 &

upcheck

echo "[*] Starting node1 node" >> qdata/gethLogs/node1.log

echo "[*] Waiting for Constellation/Tessera to start..." >> qdata/gethLogs/node1.log

upcheck

echo "[*] Starting node1 node" >> qdata/gethLogs/node1.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/node1.log

PRIVATE_CONFIG=qdata/node1.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi $ENABLED_API --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/node1.log &


#!/bin/bash
node=$1
echo $node
if [ -z "$node" ]; then
	echo "Parameter 1 is the node number"
	exit 0
fi
sudo geth attach node${node}/node/qdata/geth.ipc

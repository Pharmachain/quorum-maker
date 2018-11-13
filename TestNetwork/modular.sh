nodes="$(find . -name 'node*' -type d -maxdepth 1)"
echo $nodes

for node in `find . -name 'node*' -type d -maxdepth 1` ; do
	echo $node
	address="$(geth --exec 'personal.listAccounts' attach $node/node/qdata/geth.ipc)"
	echo $address
	address=${address::-2}
	address=${address:2}
	geth --exec "personal.unlockAccount('$address','',100000000)" attach node1/node/qdata/geth.ipc
done

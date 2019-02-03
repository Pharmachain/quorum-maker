nodes="$(find . -maxdepth 1 -name 'node*' -type d)"
echo $nodes

for node in `find . -name 'node*' -type d -maxdepth 1` ; do
	echo $node
	address="$(geth --exec 'personal.listAccounts' attach $node/node/qdata/geth.ipc)"
	address=${address#"["}
	address=${address%"]"}
	address=${address%"\""}
	address=${address#"\""}
	echo $address
	geth --exec "personal.unlockAccount('$address','',100000000)" attach node1/node/qdata/geth.ipc
done

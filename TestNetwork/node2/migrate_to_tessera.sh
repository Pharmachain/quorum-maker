#!/bin/bash

tessera="java -jar /tessera/tessera-app.jar"
tessera_data_migration="java -jar /tessera/data-migration-cli.jar"
tessera_config_migration="java -Djavax.xml.bind.JAXBContextFactory=org.eclipse.persistence.jaxb.JAXBContextFactory -Djavax.xml.bind.context.factory=org.eclipse.persistence.jaxb.JAXBContextFactory -jar /tessera/config-migration-cli.jar"

OTHER_NODES_EMPTY=$(sed -n '/othernodes/p' node/node2.conf)
if [[ -z "$OTHER_NODES_EMPTY" && -z "$1" ]]; then
    echo "No Peer defined: Run ./migrate_to_tessera.sh <URL> Eg. ./migrate_to_tessera.sh http://10.50.0.3:22002/"
    exit
fi

killall geth
killall constellation-node

mv /node2/node/qdata/node2.mv.db /node2/node/qdata/node2.mv.db.bak

sed -i "s|h2url|jdbc:h2:file:/node2/node/qdata/node2;AUTO_SERVER=TRUE|" node/tessera-migration.properties

${tessera_data_migration} -storetype dir -inputpath /node2/node/qdata/storage/payloads -dbuser -dbpass -outputfile /node2/node/qdata/node2 -exporttype JDBC -dbconfig node/tessera-migration.properties >> /dev/null 2>&1

if [ ! -f /node2/node/qdata/node2.mv.db ]; then
    mv /node2/node/qdata/node2.mv.db.bak /node2/node/qdata/node2.mv.db
fi

${tessera_config_migration} --tomlfile="node/node2.conf" --outputfile node/tessera-config.json --workdir= --socket=/node2.ipc  >> /dev/null 2>&1

sed -i "s|jdbc:h2:mem:tessera|jdbc:h2:file:/node2/node/qdata/node2;AUTO_SERVER=TRUE|" node/tessera-config.json
sed -i "s|/node2/qdata/node2|/node2|" node/tessera-config.json
sed -i "s|/node2.ipc|/node2/node/qdata/node2.ipc|" node/tessera-config.json

sed -i "s|Starting Constellation node|Starting Tessera node|" node/start_node2.sh
sed -i "s|qdata/constellationLogs/constellation_|qdata/tesseraLogs/tessera_|" node/start_node2.sh
sed -i "s|constellation-node node2.conf|\$tessera -configfile tessera-config.json|" node/start_node2.sh

if [ ! -z "$1" ]; then
    sed -i "s|\"peer\" : \[ \]|\"peer\" : \[ {\n      \"url\" : \"$1\"\n   } \]|" node/tessera-config.json     
fi

mkdir -p node/qdata/tesseraLogs

echo "Completed Tessera migration. Restart node to complete take effect."

killall NodeManager
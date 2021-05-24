#!/bin/bash
# Script to create three queue managers in three Docker containers, in a single Uniform Cluster
# Each queue manager uses the same configuration scripts to ensure their configuration is
# consistent.

# Each queue manager will accept applications to connect externally and Web administration from
# the following ports:
#             MQ application    Web/REST address
#    QM1      localhost/1411    localhost/9441
#    QM2      localhost/1412    localhost/9442
#    QM3      localhost/1413    localhost/9443

# The config files are located in the ./QMConfig directory relative to the
# location of this script, so we need to find it
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Use a CCDT containing details of all the queue managers. For now we'll use the one
# that contains these three queue managers. We can add to this later without the applications
# needing to be restarted.

# IMPORTANT: For a Uniform Cluster you need two entries for each queue manager, one for the actual
# queue manager name and another for a queu emanager group (ANY_QM in this demo)
cp $scriptDir/QMConfig/CCDT3.JSON $scriptDir/CCDT.JSON

# The queue managers will use a Docker network to talk to each other (for the Uniform Cluster
# capability). Each queue manager container publishes a unique port to allow applications to
# connect from your local machine.
docker network create mqnetwork

# Each queue maanger requires a volume for the persistent queue manager data
# Start with QM1
docker volume create qm1UCdata

# The ibmcom/mq Docker container image automatically applies MQ configuration files that
# are mounted into the /etc/mqm directory. We mount configuration files that setup the 
# Uniform Cluster (the same files can be used by every queue manager we add to that cluster)

# IMPORTANT: The naming of the network alias matches the queue manager name.
# This allows the scripted configuration to use simple MQSC name substitution for the
# channel's connection name (+QMNAME+). This avoids different config files for each
# queue manager
docker run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM1 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm1UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1411:1414 --publish 9441:9443 \
  --network mqnetwork --network-alias QM1 \
  --detach --name QM1 ibmcom/mq:latest

# Do the same for QM2 (same config files as QM1)
docker volume create qm2UCdata
docker run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM2 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm2UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1412:1414 --publish 9442:9443 \
  --network mqnetwork --network-alias QM2 \
  --detach --name QM2 ibmcom/mq:latest

# Do the same for QM3 (same config files as QM1)
docker volume create qm3UCdata
docker run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM3 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm3UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1413:1414 --publish 9443:9443 \
  --network mqnetwork --network-alias QM3 \
  --detach --name QM3 ibmcom/mq:latest

# Display the containers now running
echo
docker ps

# Display the members of the CCDT for the applications
echo
echo "CCDT.JSON queue managers:"
more $scriptDir/CCDT.JSON | grep queueManager | grep -v ANY
echo
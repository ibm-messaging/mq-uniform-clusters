#!/bin/bash
# © Copyright IBM Corporation 2021, 2022
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to create three queue managers in three Docker containers, in a single Uniform Cluster
# Each queue manager uses the same configuration scripts to ensure their configuration is
# consistent.

# Each queue manager will accept applications to connect externally and Web administration from
# the following ports:
#             MQ application    Web/REST address
#    QM1      localhost/1411    localhost/9441
#    QM2      localhost/1412    localhost/9442
#    QM3      localhost/1413    localhost/9443

# checks whether you have Docker or Podman on your 
# machine and sets the commands accordingly 
if docker -v &> /dev/null
then
    export CMDDOCKER=docker
elif podman -v &> /dev/null
then
    export CMDDOCKER=podman
else
    echo "Neither docker nor podman found"
    exit 1
fi

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
$CMDDOCKER network create mqnetwork

# Each queue maanger requires a volume for the persistent queue manager data
# Start with QM1
$CMDDOCKER volume create qm1UCdata
sleep 5

# The icr.io/ibm-messaging/mq:latest Docker container image automatically applies MQ configuration files that
# are mounted into the /etc/mqm directory. We mount configuration files that setup the 
# Uniform Cluster (the same files can be used by every queue manager we add to that cluster)

# IMPORTANT: The naming of the network alias matches the queue manager name.
# This allows the scripted configuration to use simple MQSC name substitution for the
# channel's connection name (+QMNAME+). This avoids different config files for each
# queue manager
$CMDDOCKER run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM1 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm1UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1411:1414 --publish 9441:9443 \
  --network mqnetwork --network-alias QM1 \
  --env MQ_APP_USER=app --env MQ_APP_PASSWORD=passw0rd --env MQ_ADMIN_USER=admin --env MQ_ADMIN_PASSWORD=passw0rd \
  --detach --name QM1 localhost/ibm-mqadvanced-server-dev:9.4.0.0-arm64

# Do the same for QM2 (same config files as QM1)
$CMDDOCKER volume create qm2UCdata
$CMDDOCKER run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM2 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm2UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1412:1414 --publish 9442:9443 \
  --network mqnetwork --network-alias QM2 \
  --env MQ_APP_USER=app --env MQ_APP_PASSWORD=passw0rd --env MQ_ADMIN_USER=admin --env MQ_ADMIN_PASSWORD=passw0rd \
  --detach --name QM2 localhost/ibm-mqadvanced-server-dev:9.4.0.0-arm64

# Do the same for QM3 (same config files as QM1)
$CMDDOCKER volume create qm3UCdata
$CMDDOCKER run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM3 \
  --env MQ_ENABLE_METRICS=true \
  --volume qm3UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1413:1414 --publish 9443:9443 \
  --network mqnetwork --network-alias QM3 \
  --env MQ_APP_USER=app --env MQ_APP_PASSWORD=passw0rd --env MQ_ADMIN_USER=admin --env MQ_ADMIN_PASSWORD=passw0rd \
  --detach --name QM3 localhost/ibm-mqadvanced-server-dev:9.4.0.0-arm64

# Display the containers now running
echo
$CMDDOCKER ps

# Display the members of the CCDT for the applications
echo
echo "CCDT.JSON queue managers:"
more $scriptDir/CCDT.JSON | grep queueManager | grep -v ANY
echo

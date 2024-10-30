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

# Script to add a forth queue manager to the Uniform Cluster created using createDockerCluster.sh

# Each queue manager will accept applications to connect externally and Web administration from
# the following ports:
#             MQ application    Web/REST address
#    QM1      localhost/1411    localhost/9441
#    QM2      localhost/1412    localhost/9442
#    QM3      localhost/1413    localhost/9443
#    QM3      localhost/1414    localhost/9444


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

# Update the CCDT to one containing details of all four queue managers
cp $scriptDir/QMConfig/CCDT4.JSON $scriptDir/CCDT.JSON

$CMDDOCKER volume create qm4UCdata
$CMDDOCKER run --env LICENSE=accept --env MQ_QMGR_NAME=QM4 \
  --volume qm4UCdata:/mnt/mqm \
  --volume $scriptDir/QMConfig/dockerVolume/AutoCluster.ini:/etc/mqm/AutoCluster.ini \
  --volume $scriptDir/QMConfig/dockerVolume/UniCluster.mqsc:/etc/mqm/UniCluster.mqsc \
  --publish 1414:1414 --publish 9444:9443 --network mqnetwork --network-alias QM4 \
  --env MQ_APP_USER=app --env MQ_APP_PASSWORD=passw0rd --env MQ_ADMIN_USER=admin --env MQ_ADMIN_PASSWORD=passw0rd \
  --detach --name QM4 icr.io/ibm-messaging/mq:latest

# Display the containers now running
echo
$CMDDOCKER ps

# Display the members of the CCDT for the applications
echo
echo "CCDT.JSON queue managers:"
more $scriptDir/CCDT.JSON | grep queueManager | grep -v ANY
echo

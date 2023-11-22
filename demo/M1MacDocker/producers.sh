#!/bin/bash
# © Copyright IBM Corporation 2021
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

# Script to start up multiple instances of a demo MQ producing application that'll each produce
# a message every second

# IMPORTANT: You'll need the MQ sample bin directory (often /opt/mqm/samp/bin) in you path

# The config files are located in the ./QMConfig directory relative to the
# location of this script, so we need to find it
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Applications use a CCDT to set the connection details for the Uniform Cluster. This will
# have been put in place by createDockerCluster.sh
export MQCHLLIB=$scriptDir
export MQCHLTAB=CCDT.JSON


# Producing MQ demo application
appName="amqsphac"

appCount=${1:-12}          # Number of application instances
queueName=${2:-"DEV.QUEUE.1"}   # Queue to produce to
qmgrName=${3:-"*ANY_QM"}       # Queue manager group to connect to

# Set the output to the same colour used by connections.sh
echo -e '\033[0;93m'

# Start multiple application instances
for (( i=0; i<$appCount; ++i)); do
  echo "Starting $appName"
  $appName $queueName $qmgrName &
  # Stagger the applications slightly, just so their output is smoother for the screen
  sleep 0.2
done

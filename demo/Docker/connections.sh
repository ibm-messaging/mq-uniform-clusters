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

# Script to poll a queue manager for demo app connections and display them as individual lines

# This is expecting to find connections from two applications:
#    amqsphac - Sample putting application
#    amqsghac - Sample getting application

# Usage:
#    connections qmgr_name <poll interval> <admin_password>

# Use different colours for the different applications
green='\033[0;32m'
lgreen='\033[0;92m'
red='\033[0;31m'
producers='\033[0;93m'
consumers='\033[0;92m'
nc='\033[0m'

# The config files are located in the ./QMConfig directory relative to the
# location of this script, so we need to find it
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# As we're connecting runmqsc as a client into a container, we use the CCDT configured for
# the developer defaults admin channel
export MQCHLLIB=$scriptDir/QMConfig
export MQCHLTAB=CCDT_ADMIN.JSON

# Queue manager name (e.g. QM1)
qmName=$1
# Poll interval in seconds (default 1 second)
delay=${2:-1}
# Admin password (default passw0rd)
password=${3:-passw0rd}

# You need runmqsc available on the host system so that it can connect to the
# queue manager running in the container
if [ ! -x "$(command -v runmqsc)" ]; then
  echo 'ERROR: runmqsc not found on local system'
else
  for (( i=0; i<100000; ++i)); do
    # Grab a list of connections for each application and stash them in /tmp
    `(echo "$password"; echo "dis conn(*) where(appltag eq 'amqsphac')") | runmqsc -c -u admin $qmName 2> /dev/null 1> /tmp/showConn.$qmName.amqsphac`
    `(echo "$password"; echo "dis conn(*) where(appltag eq 'amqsghac')") | runmqsc -c -u admin $qmName 2> /dev/null 1> /tmp/showConn.$qmName.amqsghac`

    # See if runmqsc connected, i.e. the queue manager is running  
    running=`grep -e "AMQ9202E" /tmp/showConn.$qmName.amqsphac | wc -l`

    # Count up each application
    connCountP=`grep -e "  CONN" /tmp/showConn.$qmName.amqsphac | wc -w`
    connCountG=`grep -e "  CONN" /tmp/showConn.$qmName.amqsghac | wc -w`

    # Just refresh what's in the terminal on each poll
    clear
    if [ $running -eq 1 ]
    then
      echo -e "${red}$1 not available${nc}"
    else
      # Display each connection
      echo -e "${green}$1${nc}"
      echo -e "${producers}producers:$connCountP${consumers}  consumers:$connCountG${nc}"
      echo -e "${producers}"
      grep -e "  CONN" /tmp/showConn.$qmName.amqsphac
      echo -e "${consumers}"
      grep -e "  CONN" /tmp/showConn.$qmName.amqsghac
      echo -e "${nc}"
    fi
    # Wait for the next poll
    sleep $delay
  done
fi
#!/bin/bash
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
putters='\033[0;93m'
getters='\033[0;92m'
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
    echo -e "${putters}putters:$connCountP${getters}  getters:$connCountG${nc}"
    echo -e "${putters}"
    grep -e "  CONN" /tmp/showConn.$qmName.amqsphac
    echo -e "${getters}"
    grep -e "  CONN" /tmp/showConn.$qmName.amqsghac
    echo -e "${nc}"
  fi
  # Wait for the next poll
  sleep $delay
done

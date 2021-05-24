#!/bin/bash
# Script to start up multiple instances of a demo MQ producing application that'll each produce
# a message every second

# IMPARTANT: You'll need the MQ sample bin directory (often /opt/mqm/samp/bin) in you path

# The config files are located in the ./QMConfig directory relative to the
# location of this script, so we need to find it
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Applications use a CCDT to set the connection details for the Uniform Cluster. This will
# have been put in place by createDockerCluster.sh
export MQCHLLIB=$scriptDir
export MQCHLTAB=CCDT.JSON

# The MQ Developer Docker container has a default application user configured, 'app'
export MQSAMP_USER_ID=app

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

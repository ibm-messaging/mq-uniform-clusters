#!/bin/bash

# This script starts multiple instances on a sample MQ application.
# This sample, amqsghac, is provided with the MQ SDK package.
# It was chosen because it uses the auto-reconnect feature of MQ which
# means the queue managers will automatically move a connection from
# this application between queue managers in a Uniform Cluster to
# achieve an even balance of connections from applications of the same
# name

# The application will connect using the details within the CCDT.JSON
# file which is found in the same directory as this script (once
# createCluster.sh has been run)
rel_dir="$(dirname "$0")"
export MQCHLLIB=$rel_dir
export MQCHLTAB=CCDT.JSON

# Check that the CCDT.JSON file exists before starting the applications
if [ -f "$MQCHLLIB/$MQCHLTAB" ]; then

  # Start multiple instances of the sample application
  for (( i=0; i<$1; ++i)); do
    amqsghac Q1 *ANY_QM &
  done

else
  echo "$MQCHLLIB/$MQCHLTAB not found"
fi

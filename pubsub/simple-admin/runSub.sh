#!/bin/bash
# © Copyright IBM Corporation 2020
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

# This script starts multiple instances of a sample MQ application.
# This sample, amqsghac, is provided with the MQ SDK package.
# It was chosen because it uses the auto-reconnect feature of MQ which
# means the queue managers will automatically move a connection from
# this application between queue managers in a Uniform Cluster to
# achieve an even balance of connections from applications of the same
# name

# In this example the queue which amqsghac reads from happens to be
# the destination queue for a manually configured subscription, this
# does not effect the rebalancing behaviour for the application

# The application will connect using the details within the CCDT.JSON
# file which is found in the same directory as this script (once
# createCluster.sh has been run)
rel_dir="$(dirname "$0")"
export MQCHLLIB=$rel_dir
export MQCHLTAB=CCDT.JSON

# parm 1 - instance count
# default to starting 6 getter instances
INSTANCES="${1:-6}"

# parm 2 - subscriber queue name
# default to DESTQ1 (see QMConfig/UniCluster.mqsc)
QNAME="${2:=DESTQ1}"

# parm 3 - application name
# default to the name of the executable
if [ -n $3 ]; then
  export MQAPPLNAME=$3
fi

# Check that the CCDT.JSON file exists before starting the applications
if [ -f "$MQCHLLIB/$MQCHLTAB" ]; then

  # Start multiple instances of the sample application
  for (( i=0; i<$INSTANCES; ++i)); do
    $MQ_INSTALLATION_PATH/samp/bin/amqsghac $QNAME *ANY_QM &
  done

else
  echo "$MQCHLLIB/$MQCHLTAB not found"
fi

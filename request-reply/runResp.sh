#!/bin/bash
# © Copyright IBM Corporation 2020, 2021
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

INSTANCES="${1:-12}"

# Check that the CCDT.JSON file exists before starting the applications
if [ -f "$MQCHLLIB/$MQCHLTAB" ]; then

  # Start multiple instances of the sample application
  for (( i=0; i<$INSTANCES; ++i)); do
    $rel_dir/mqresponder -m *ANY_QM -s REQQ &
  done

else
  echo "$MQCHLLIB/$MQCHLTAB not found"
fi

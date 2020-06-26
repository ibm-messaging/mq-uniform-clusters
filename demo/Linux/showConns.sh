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

# This script simply queries a queue manager for the connections and displays them
# This helps see when applications are rebalanced across a Uniform Cluster

# Provide the queue manager name to monitor on the command line
if [ $# -eq 0 ]; then
  echo "Provide the queue manager name to monitor"
  exit
fi
qmgr=$1

# Check that the queue manager name is valid and available
if [ $(dspmq -m $qmgr | grep '(Running)' | wc -w) -eq 0 ]; then
  echo "$qmgr not available"
  exit
fi

# Optionally you can override the application name to monitor
app_name=${2:-amqsghac}
# And the time between updates
delay=${3:-1s}

for (( i=0; i<100000; ++i)); do
  # First count up the number of matching connections
  conn_count=`echo "dis conn(*) where(appltag eq '$app_name')" | runmqsc $qmgr | grep "  CONN" | wc -w`
  clear
  echo -e "$qmgr / ${green}$app_name -- $conn_count"
  # Display an entry for each matching connection
  echo "dis conn(*) where(appltag eq '$app_name')" | runmqsc $qmgr | grep "  CONN"

  # Wait before repeating
  sleep $delay
done

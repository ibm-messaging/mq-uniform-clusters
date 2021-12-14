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

# Create a forth queue manager in the Uniform Cluster

# The config files are located in the ./QMConfig directory relative to the
# location of this script
rel_dir="$(dirname "$0")"

# Check that the QMConfig directory exists where we expected it to
if [ -d "$rel_dir/QMConfig" ]; then

  echo "Create QMGR4 on port 1404 using the same config files as the other queue mangers"
  echo "crtmqm -ii $rel_dir/QMConfig/AutoCluster.ini -ic $rel_dir/QMConfig/UniCluster.mqsc -iv CONNAME=""127.0.0.1(1404)"" -p 1404 QMGR4"
  read -p "Press enter to execute"
  crtmqm -ii $rel_dir/QMConfig/AutoCluster.ini -ic $rel_dir/QMConfig/UniCluster.mqsc -iv CONNAME="127.0.0.1(1404)" -p 1404 QMGR4

  echo "Replace the 3 queue manager CCDT with one that includes QMGR4"
  echo "The existing applications will dynamically reload the new CCDT"
  echo "cp $rel_dir/QMConfig/CCDT4.JSON $rel_dir/CCDT.JSON"
  read -p "Press enter to execute"
  cp $rel_dir/QMConfig/CCDT4.JSON $rel_dir/CCDT.JSON

  echo "Start QMGR4 and see the connections rebalance"
  echo "strmqm QMGR4"
  read -p "Press enter to execute"
  strmqm QMGR4
else
  echo "$rel_dir/QMConfig not found"
fi


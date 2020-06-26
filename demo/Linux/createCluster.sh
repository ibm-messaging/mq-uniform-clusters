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

# Create three queue managers in a single Uniform Cluster
# Each queue manager is based off the same configuration files
# Each queue manager listens on a unique port and is specified at create time

# The config files are located in the ./QMConfig directory relative to the
# location of this script
rel_dir="$(dirname "$0")"

# Check that the QMConfig directory exists where we expected it to
if [ -d "$rel_dir/QMConfig" ]; then

  # Create QMGR1 and listen on port 1401
  crtmqm -ii $rel_dir/QMConfig/AutoCluster.ini -ic $rel_dir/QMConfig/UniCluster.mqsc -iv CONNAME="127.0.0.1(1401)" -p 1401 QMGR1

  # Create QMGR2 and listen on port 1402
  crtmqm -ii $rel_dir/QMConfig/AutoCluster.ini -ic $rel_dir/QMConfig/UniCluster.mqsc -iv CONNAME="127.0.0.1(1402)" -p 1402 QMGR2

  # Create QMGR3 and listen on port 1403
  crtmqm -ii $rel_dir/QMConfig/AutoCluster.ini -ic $rel_dir/QMConfig/UniCluster.mqsc -iv CONNAME="127.0.0.1(1403)" -p 1403 QMGR3

  # Make the three queue manager CCDT (QMConfig/CCDT3.JSON) the active CCDT (CCDT.JSON)
  # for the test application to use
  cp $rel_dir/QMConfig/CCDT3.JSON $rel_dir/CCDT.JSON

else
  echo "$rel_dir/QMConfig not found"
fi

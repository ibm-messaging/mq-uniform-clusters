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

# Script to delete the queue managers in the uniform cluster, this may be three 
# or four queue managers

# checks whether you have Docker or Podman on your 
# machine and sets the commands accordingly 
if docker -v &> /dev/null
then
    export CMDDOCKER=docker
elif podman -v &> /dev/null
then
    export CMDDOCKER=podman
else
    echo "Neither docker nor podman found"
    exit 1
fi

#docker stop QM1
$CMDDOCKER stop QM1
$CMDDOCKER rm QM1
$CMDDOCKER volume rm qm1UCdata

#docker stop QM2
$CMDDOCKER stop QM2
$CMDDOCKER rm QM2
$CMDDOCKER volume rm qm2UCdata

#docker stop QM3
$CMDDOCKER stop QM3
$CMDDOCKER rm QM3
$CMDDOCKER volume rm qm3UCdata

#docker stop QM4
$CMDDOCKER stop QM4
$CMDDOCKER rm QM4
$CMDDOCKER volume rm qm4UCdata

$CMDDOCKER network rm mqnetwork

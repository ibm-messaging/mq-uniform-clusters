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

#docker stop QM1
docker stop QM1
docker rm QM1
docker volume rm qm1UCdata

#docker stop QM2
docker stop QM2
docker rm QM2
docker volume rm qm2UCdata

#docker stop QM3
docker stop QM3
docker rm QM3
docker volume rm qm3UCdata

#docker stop QM4
docker stop QM4
docker rm QM4
docker volume rm qm4UCdata

docker network rm mqnetwork

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

# This script simply kills all matching processes, defaulting
# to the MQ 'requester' and 'responder' samples

app_name1=${1:-mqrequester}
app_name2=${2:-mqresponder}

kill $(ps -e | grep $app_name1 | awk '{print $1}')
kill $(ps -e | grep $app_name2 | awk '{print $1}')

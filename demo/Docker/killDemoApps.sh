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

# Kill off all the instances of the demo applications (amqsphac and amqsghac)

COUNT=${2:-999}

kill $(ps -e | grep amqsphac | grep -v grep | head -$COUNT | awk '{print $1}')
kill $(ps -e | grep amqsghac | grep -v grep | head -$COUNT | awk '{print $1}')



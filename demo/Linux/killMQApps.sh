#!/bin/bash
# This script simply kills all matching processes, defaulting
# to the MQ sample amqsghac

app_name=${1:-amqsghac}

kill $(ps -e | grep $app_name | awk '{print $1}')

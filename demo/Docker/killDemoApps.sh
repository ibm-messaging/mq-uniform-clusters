#!/bin/bash
# Kill off all the instances of the demo applications (amqsphac and amqsghac)

COUNT=${2:-999}

kill $(ps -e | grep amqsphac | grep -v grep | head -$COUNT | awk '{print $1}')
kill $(ps -e | grep amqsghac | grep -v grep | head -$COUNT | awk '{print $1}')



# Running the Demo

## Prerequisites

The demo scripts and configuration have been produced for a Linux installation of IBM MQ, version **9.1.4** or above. You're welcome to take the concepts from the scripts and apply these to other platforms that support Uniform Clusters.

You can obtain the latest version of [IBM MQ Advanced for Developers](https://developer.ibm.com/articles/mq-downloads/#get-a-queue-manager-mq-server) for free to try this out on.

If you're new to IBM MQ you might want to follow these instructions for getting [IBM MQ installed on Ubuntu](https://developer.ibm.com/tutorials/mq-connect-app-queue-manager-ubuntu/) (although you only need to follow steps 1-4 for this demo).

The scripts expect your environment to be setup to run the MQ commands (e.g. by running `/opt/mqm/bin/setmqenv -s`)

## The setup

This demo is based on three queue managers configured as a Uniform Cluster. This is done simply by pointing all three queue managers at the same configuration scripts `QMConfig/AutoCluster.ini` and `QMConfig/UniCluster.mqsc`.

### 1. Create the queue managers
`createCluster.sh` scripts the creation of three queue managers.

This script also places a CCDT (all the application connection details) for the three queue managers in a location ready for the applications in step 4

### 2. Start the queue managers
`startCluster.sh` starts the three queue managers ready for the demo.

### 3. Prepare for connections
As the demo is showing how application connections are automatically balanced across queue managers you need to see where the connections go. This can be done in a number of ways but the script `showConns.sh` is a convenient way to keep an eye on each of the queue managers. For the purposes of the demo it is best to start three separate terminals and run `showConns.sh QMGRx` for each of the queue managers.

### 4. Start the applications
A Uniform Cluster automatically maintains an even balance of multiple connections with the same application name across all queue managers in the Uniform Cluster. This requires the application to indicate that they are available to be moved, this is through use of the [auto-reconnect setting](https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.pla.doc/q132740_.htm) used by the application. For this reason the demo uses the IBM MQ sample `amqsghac` which sets that option, although you could use your own application.

The script `rClient.sh n` is used to start multiple instances of the application, where **n** is the number of instances.

The applications connect to a virtual queue manager name `*ANY_QM` this is configured in the `CCDT3.JSON` file for each of the queue managers. This  enables approximate distribution of the initial connections, with the Uniform Cluster fine tuning that distribution once connected. Entries in the CCDT for each individual queue manager are there to support moving connections from one queue manager to another.

### 5. Watch for connections

At this point the terminals running `showConns.sh` should start to display the connections to each queue manager.

If there is an imbalance in the connections across the Uniform Cluster this will start to be corrected automatically within seconds.

### 6. Experiment

At this point you have multiple applications connected and the Uniform Cluster constantly monitoring them. Things to try are:

#### Add more connections
As more connections are added, they will be rebalanced as needed

#### Stop and start queue managers
Stopping and starting a queue manager will show connections being moved to alternative queue managers and then connections being rebalanced once the queue manager is available again.

**Note:** that you'll probably want to end the queue manager using `endmqm -r QMGRx`, otherwise the connected applications will terminate their connections rather than move them.

#### Add another queue manager to the cluster
As each of the queue managers are configured from the same set of configuration it is very easy to add more queue managers. To do that you need to perform three steps:

1. Create the queue manager using a similar `crtmqm` command found in `createCluster.sh`, only needing to change the queue manager name and the two points where the port is set in that command.
2. Add new entries to the CCDT, this will automatically be picked up by the existing applications.
3. Start the new queue manager.

The `addQMGR4.sh` script automates the above three steps

# Running the Demo

## Prerequisites

The demo scripts and configuration have been produced for Docker using the IBM MQ Advanced for Developers image from https://hub.docker.com/r/ibmcom/mq/.

The bash scripts are written to work on MacOS and should also work on Linux

As well as the Docker containers the system you run this demo on will need both Docker installed and an IBM MQ base client and samples. For example, those found at https://developer.ibm.com/articles/mq-downloads/#c-lang. From this you'll need both the location of the runmqsc and the pre-built samples in your path.

## The setup

This demo is based on three queue managers configured as a Uniform Cluster.

### 1. Create the queue managers
`createDockerCluster.sh` scripts the creation and running of three queue managers as three containers.

This script also places a CCDT (all the application connection details) for the three queue managers in a location ready for the applications in step 4

### 3. Prepare for connections
As the demo is showing how application connections are automatically balanced across queue managers you need to see where the connections go. This can be done in a number of ways but the script `connections.sh` is a convenient way to keep an eye on each of the queue managers. For the purposes of the demo it is best to start three separate terminals and run `connections/sh QMx` for each of the queue managers.

### 4. Start the applications
For the demo, we'll create a set of producing applications and a set of consuming applications.

A Uniform Cluster automatically maintains an even balance of multiple connections with the same application name across all queue managers in the Uniform Cluster. This requires the application to indicate that they are available to be moved, this is through use of the [auto-reconnect setting](https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.pla.doc/q132740_.htm) used by the application. For this reason the demo uses the IBM MQ samples `amqsphac` and `amqsghac` which set this option, although you could use your own application.

It's best to have two terminals open, one for the producers and one for the consumers. 

To start the producers run `producers.sh`, and to start the consumers run `consumers.sh`.

The applications connect to a virtual queue manager name `*ANY_QM` this is configured in the `CCDT3.JSON` file, for each of the queue managers. This enables approximate distribution of the initial connections, with the Uniform Cluster fine tuning that distribution once connected. Entries in the CCDT for each individual queue manager are there to support moving connections from one queue manager to another.

### 5. Watch for connections

At this point the terminals running `connections.sh` should start to display the connections to each queue manager.

If there is an imbalance in the connections across the Uniform Cluster this will start to be corrected automatically within seconds.

### 6. Experiment

At this point you have multiple applications connected and the Uniform Cluster constantly monitoring them. Things to try are:

#### Add more connections
As more connections are added, they will be rebalanced as needed

#### Stop and start queue managers
Stopping and starting a queue manager will show connections being moved to alternative queue managers and then connections being rebalanced once the queue manager is available again.

As the queue managers are inside containers, simply use `docker stop QMx` and `docker start QMx`.

#### Add another queue manager to the cluster
As each of the queue managers are configured from the same set of configuration it is very easy to add more queue managers. To do that, run `addQM4.sh`. This does the following:

1. Create the queue manager using a similar command found in `createDockerCluster.sh`, only needing to change the queue manager name and the two points where the port is set in that command.
2. Add new entries to the CCDT by copying `CCDT4.JSON` over `CCDT.JSON`, this will automatically be picked up by the existing applications.
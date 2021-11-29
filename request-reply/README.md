# Running the Demo

## Prerequisites

This is a more advanced scenario based on the simple Uniform Clusters demo found at https://github.com/ibm-messaging/mq-uniform-clusters/tree/master/demo 

It demonstrates use of new features in IBM MQ 9.2.4 and higher to enable rebalancing of applications with limited affinity to individual queue managers due to use of the request response pattern.

The demo scripts and configuration have been produced for a Linux installation of IBM MQ, version **9.2.4** or above. You're welcome to take the concepts from the scripts and apply these to other platforms that support Uniform Clusters.  You do not neccessarily need to run the connecting applications on the same system as your queue managers - for example, if your day to day development environment is OSX you can build and run the sample applications on this system and connect to an MQ server running on another host, (or a local container or VM image).  Simply update the CCDTs accordingly to provide network information for the queue managers.

You can obtain the latest version of [IBM MQ Advanced for Developers](https://developer.ibm.com/articles/mq-downloads/#get-a-queue-manager-mq-server) for free to try this out on.

If you're new to IBM MQ you might want to follow these instructions for getting [IBM MQ installed on Ubuntu](https://developer.ibm.com/tutorials/mq-connect-app-queue-manager-ubuntu/) (although you only need to follow steps 1-4 for this demo).

The scripts expect your environment to be setup to run the MQ commands (e.g. by running `/opt/mqm/bin/setmqenv -s`)

## Before you start - Understand and build the client applications

The src directory contains two sample programs which are used in this demonstration.

The *mqrequester* application, as the name suggests implements the 'request side' of our simple request/response scenario. It demonstrates connection to a queue manager supplying the new MQBNO structure containing information about how this application should be rebalanced.  By identifying itself as a 'Request Response' application, it indicates that it should not be rebalanced while waiting for outstanding replies.

The *mqresponder* application is even simpler, it performs a simple MQCONN only, and waits indefinitely for 'request' messages.  Whenever a request is received, it 'sleeps' for 15 seconds to simulate some processing work, before responding the the request application at the specified replyToQ and replyToQMgr.  Balancing information for this application is provided only via the mqclient.ini file, and overrides the TIMEOUT only.

Both of these applications also register an event handler callback which notes the processing of any asynchronous reconnect request received.

### Compiling the applications - Linux (gcc)

For the MQ library dependencies you will need an IBM MQ installation (either client or server) or the redistributable client libraries. If you have installed IBM MQ Advanced for Developers as described above this provides everything you need.

gcc src/mqrequester.c src/utils.c -I $MQ_INSTALL_PATH/inc -L $MQ_INSTALL_PATH/lib64 -lmqic_r -Wl,-rpath $MQ_INSTALL_PATH/lib64/ -o mqrequester
gcc src/mqresponder.c src/utils.c -I $MQ_INSTALL_PATH/inc -L $MQ_INSTALL_PATH/lib64 -lmqic_r -Wl,-rpath $MQ_INSTALL_PATH/lib64/ -o mqresponder

### Compiling the applications - OSX (clang)

With the [MacOS Toolkit](https://developer.ibm.com/tutorials/mq-macos-dev/) and the XCode development environment installed you can build and run the client natively on OSX using clang:

clang src/mqrequester.c src/utils.c -I $MQ_INSTALL_PATH/inc -L $MQ_INSTALL_PATH/lib64 -lmqic_r -Wl,-rpath $MQ_INSTALL_PATH/lib64/ -o mqrequester
clang src/mqresponder.c src/utils.c -I $MQ_INSTALL_PATH/inc -L $MQ_INSTALL_PATH/lib64 -lmqic_r -Wl,-rpath $MQ_INSTALL_PATH/lib64/ -o mqresponder

### Compiling the applications - Windows

The application is designed for portablity to Windows but has not yet been tested/verified in this environment - please feel free to try this out and update as appropriate!

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
A Uniform Cluster automatically maintains an even balance of multiple connections with the same application name across all queue managers in the Uniform Cluster. This requires the application to indicate that they are available to be moved, this is through use of the [auto-reconnect setting](https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.pla.doc/q132740_.htm) used by the application. For this demonstration we use two specially created sample applications, and will run multiple instances of each.

The scripts `runReq.sh n` and `runResp.sh n` start multiple instances of each application, where **n** is the number of instances, defaulting to 12.  It is suggested that you start these in a further two separate terminal windows (so you should now have 5 sessions visible - 3 'monitoring' windows running the showConns script, and one each for requester and responder application output.)

The applications connect to a virtual queue manager name `*ANY_QM` this is configured in the `CCDT3.JSON` file for each of the queue managers. This  enables approximate distribution of the initial connections, with the Uniform Cluster fine tuning that distribution once connected. Entries in the CCDT for each individual queue manager are there to support moving connections from one queue manager to another.

### 5. Watch for connections

At this point the terminals running `showConns.sh` should start to display the connections to each queue manager.

If there is an imbalance in the connections across the Uniform Cluster this will start to be corrected automatically within seconds.  You should notice that the simple 'responder' apps rebalance very swiftly, while the 'requester' apps, as indicated in their BNO options, wait to receive outstanding responses before moving to establish the balance.

The 'requester' and 'responder' applications are fairly verbose in their output, showing sending and receiving of each message and also the processing of any reconnect/rebalance events.  This becomes more useful as you experiment with modifications to the programs or configuration (for example if an application does not receive an expected message you will see this here).

### 6. Experiment

At this point you have multiple applications connected and the Uniform Cluster constantly monitoring them. Things to try are:

#### Add another queue manager to the cluster
As each of the queue managers are configured from the same set of configuration it is very easy to add more queue managers. To do that you need to perform three steps:

1. Create the queue manager using a similar `crtmqm` command found in `createCluster.sh`, only needing to change the queue manager name and the two points where the port is set in that command.
2. Add new entries to the CCDT, this will automatically be picked up by the existing applications.
3. Start the new queue manager.

The `addQMGR4.sh` script automates the above three steps

When a new queue manager becomes available, you should again notice that simple 'responder' apps are swift to rebalance, while 'requester' apps wait for an appropriate point to do so without losing their response messages.

#### Modify the sample applications

The sample applications should provide a good base to experiment with many options that can influence how and when rebalancing will occur.  One very simple experiment is to modify the responder app to perform its 'GET' and 'PUT' operations under syncpoint.  The rebalancing algorithm will now attempt to avoid interrupting operations until committed (so up to 15s while processing a response message).  By modifying the timings, you could also demonstrate the 'interruption' behaviour when the balancing timeout is exceeded.

To modify the BNO settings used by an application you can also experiment with changes to the mqclient.ini file - these will be picked up the next time the client application restarts.

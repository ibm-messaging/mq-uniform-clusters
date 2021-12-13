# Running the Demo

## Prerequisites

These scripts provide a demonstration for one of the simplest possible publish subscribe patterns in a Uniform Cluster.  The Cluster is used purely to scale a subscribing application horizontally by balancing a pool of instances across several queue managers. This pool must include at least sufficient instances for there always to be one connected to each queue manager in the cluster.  The application must NOT rely on all publications (or all publications from a particular source) being processed by the same subscriber instance.

In this scenario:
* although messages are routed to target queues via MQ Topics, the receiving applications are simple 'Getter's (in fact the sample amqsghac is used). 
* No queue manager to queue manager message flows are required as messages are always processed at a local instance of the application.
* Publisher(s) may connect to any queue manager in the cluster
* Multiple 'discrete' applications can easily be supported on the same topics (each requiring their own administrative subscriptions on each queue manager)

Before starting, consider familiarising yourself with the 'simple' Uniform Cluster demonstration in [demo](../../../demo)

## The setup

This demo is based on three queue managers configured as a Uniform Cluster. This is done simply by pointing all three queue managers at the same configuration scripts `QMConfig/AutoCluster.ini` and `QMConfig/UniCluster.mqsc`.

### 1. Create the queue managers
`createCluster.sh` scripts the creation of three queue managers.  Note that this uses the relatively new 'template' mechanism to provide the same initial cluster and object configuration to each created queue manager at crtmqm time.  As well as the cluster channel configuration, all queues, topics, and subscriptions used by the sample programs are defined in [QMConfig/UniCluster.mqsc](QMConfig/UniCluster.mqsc)

Note that none of these objects are themselves clustered.  This is because for this example all applications work only with local objects - the Uniform Cluster here provides *only* application balancing for the subscribing applications.

This script also places a CCDT (all the application connection details) for the three queue managers in a location ready for the applications in step 4

### 2. Start the queue managers
`startCluster.sh` starts the three queue managers ready for the demo.

### 3. Prepare for connections
As the demo is showing how application connections are automatically balanced across queue managers you need to see where the connections go. This can be done in a number of ways but the script `showConns.sh` is a convenient way to keep an eye on each of the queue managers. For the purposes of the demo it is best to start three separate terminals and run `showConns.sh QMGRx` for each of the queue managers.

### 4. Start the receiving applications
A Uniform Cluster automatically maintains an even balance of multiple connections with the same application name across all queue managers in the Uniform Cluster. This requires the application to indicate that they are available to be moved, this is through use of the [auto-reconnect setting](https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.pla.doc/q132740_.htm) used by the application. For this reason the demo uses the IBM MQ sample `amqsghac` which sets that option and also conveniently reports reconnection events as and when they occur.

The script `runSub.sh n` is used to start multiple instances of the application, where **n** is the number of instances.  Launch at least as many instances as there are queue managers - for example 6 instances will result in 2 per queue manager.

The applications connect to a virtual queue manager name `*ANY_QM` this is configured in the `CCDT3.JSON` file for each of the queue managers. This  enables approximate distribution of the initial connections, with the Uniform Cluster fine tuning that distribution once connected. Entries in the CCDT for each individual queue manager are there to support moving connections from one queue manager to another.

### 5. Start the publishing applications

At this point the terminals running `showConns.sh` should start to display the subscribing connections to each queue manager.  (If there is an initial imbalance this should be corrected automatically within seconds.)

Using a new terminal for each instance, you can now start some publishing applications using `runPub.sh`.  This launches the amqspub sample using the same CCDT and again connecting to *ANY_QM.
Note that although amqspub does not specify itself as reconnectable by default, the CCDT we are providing marks these channels as being reconnectable, so this is enabled without changes to the application code.  

As above for amqsghac, the amqspub instances will now be balanced across queue managers - though because application rebalancing usually occurs during an MQI call, you may see that instances do not rebalance *until* they send a message driving communication to the queue manager.  (As amqsghac spends most of its time in a 'waiting get' this is usually instantaneous for that application).

The launched instances are interactive so you can send messages by simply typing into the new terminals.  Note that regardless of how many instances of the 'subscribing application' you ran, and where they are currently connected, only one instance receives each publication.  (As messages are received they will be echoed to the terminal where you ran `runSub.sh`).

### 6. Experiment

At this point you have multiple applications connected and the Uniform Cluster constantly monitoring them. Things to try are:

#### Add more connections

As more publishers or subscribers are added, they will be rebalanced as needed.  In a 'real world' implementation of this scenario you might aim to always have *(number of queue managers) + n* instances of the subscribing application for availability reasons, where n is the number of 'application instance failures' you need to be able to tolerate before some publications may not be processed (at least in a timely manner).  

Publishing applications are more likely to be driven by architectural considerations - where does the data come from and how many 'instances' of that source make sense - but this example demonstrates that it does not matter how many publishers are connected or which particular queue manager they connect to.  Note that we have chosen NOT to cluster the destination queues in this example, but if the type of workload involved heavy 'back end' processing on the subscriber, it might be desirable to workload balance publications across the cluster by doing so - it would also be neccessary to modify CLWLUSEQ to acheive this.

(Note: For this style of 'single instance' delivery it is vital NOT to cluster the Topic objects, as this would result in multiple subscriptions receiving the same message)

#### Add 'discrete' subscribing applications

The scenario shown here assumes that for each publication, we only want a single instance of a given receiving application to receive the message.  However, this does not conflict with multiple, *discrete*, applications subscribing to the same topic and each receiving a copy of the message.

To add an additional subscribing application we need only:

1. Define the new administrative subscription and destination queue on each queue manager
e.g.
  DEFINE QLOCAL(NEWQ) DEFPSIST(YES)
  DEFINE SUB(NEWSUB) TOPICOBJ(TESTTOP) DEST(NEWQ) 

This could be done directly using any administrative interface (e.g. runmqsc).  However, you also have the option in this example configuration to update the shared QMConfig/UniCluster.mqsc with the additional definitions, and these will be picked up on restart - why not try this now?  *Remember when ending/restarting a queue manager to use `endmqm -r`* this requests that applications automatically reconnect, so that they see no outage when any given queue manager stops and restarts (at which point application rebalancing will restore an appropriate share of connections to the restarted QM).

2. Ensure that all instances of our applications connect with the same application name (unique to this application)

By default, the application name is the name of the launched executable - however we can easily override this in several ways.  One of these is using the environment variable MQAPPLNAME, which the `runSub.sh` script conveniently exposes as a parameter.  

The reason that the application name is important is that application rebalancing is _per application_ - when ensuring an even spread of connections, this is the key which the queue manager will use to distinguish between 'related' and 'unrelated' application instances.

3. Start at least as many instances of the new application as we have queue managers.
Use the additional parameters to runSub to start a number of instances of the same program (amqsghac), now identifed as an entirely separate program reading from our new subscription queue:
`./runSub.sh 6 NEWQ NewGetter`

Note that the existing showConns terminals will not show our new application connections as they are only listing instances of amqsghac and amqspub (you can modify or use the parameters to change this if you wish).  However, for now lets interactively check the spread of our 'new' application instances using runmqsc:
  runmqsc QMGR1
  DIS APSTATUS('NewGetter') type(QMGR)

If you now publish a message to the same topic string as before (runPub / amqspub) you will see that now 2 copies of the message are delivered, one to an instance of 'amqsghac' and one to an instance of 'NewGetter'.  Again, it makes no difference where the publisher is connected or how many instances of the getter(s) are running.

#### Add another queue manager to the cluster
As each of the queue managers are configured from the same set of configuration it is very easy to add more queue managers. To do that you need to perform three steps:

1. Create the queue manager using a similar `crtmqm` command found in `createCluster.sh`, only needing to change the queue manager name and the two points where the port is set in that command.
2. Add new entries to the CCDT, this will automatically be picked up by the existing applications.
3. Start the new queue manager.

The `addQMGR4.sh` script automates the above three steps

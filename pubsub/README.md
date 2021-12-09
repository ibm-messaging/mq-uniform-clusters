# Publish Subscribe scenarios for Uniform Clusters

This project contains several different examples of using publish subscribe applications in a Uniform cluster environment.  Before investigating these more advanced scenarios you may want to familiarise yourself with the basic Uniform Cluster demonstration/example in [demo](../../demo)

## Pre-amble - what makes Pub-Sub in Uniform Clusters 'special'?

There are many ways of configuring Publish Subscribe in IBM MQ, some of which are suitable for use with Uniform Cluster application rebalancing and some of which present significant problems with the current product capabilities.  In general, application balancing is not safe for use with application code which relies on 'affinity' to a particular queue manager, unless that affinity can be described using specific application patterns at connection time.  At time of writing (IBM MQ 9.2.4), Uniform Clusters can have awareness of two such types of affinity - Transaction state and Request-Reply state.

Publish subscribe often creates a different sort of affinity, which the balancing algorithm cannot currently compensate for.  Therefore only patterns of publish subscribe which do not create such affinities are currently safe.  This project provides examples of the kind of pub sub deployments which *can* benefit from Uniform Clusters today.

(It is also worth noting that if an application does not fit these patterns, it does not mean that it *cannot* be deployed into a Uniform Cluster 'estate'.  If you *know* that the application model is unsuitable for rebalancing, you can still deploy your application against a Uniform Cluster queue manager, but should configure the MQCNO_RECONNECT value to either DISABLED (no automatic reconnection) or QMGR (reconnect only to the same queue manager) - this will prevent applications being automatically moved from queue manager to queue manager to spread load.)

## The pub sub patterns:

### Simple administrative publish subscribe ([simple-admin](simple-admin))

[admin](simple-admin) demonstrates one of the simplest possible publish subscribe patterns.  The Uniform Cluster is used purely to scale a subscribing application horizontally by balancing a pool of instances across several queue managers. This pool must include at least sufficient instances for there always to be one connected to each queue manager in the cluster.  The application must NOT rely on all publications (or all publications from a particular source) being processed by the same subscriber instance.

In this scenario:
* although messages are routed to target queues via MQ Topics, the applications are simple MQ 'Putter's and 'Getter's (in fact the reconnectable samples amqsghac and amqsphac are used). 
* No queue manager to queue manager message flows are required as messages are always processed at a local instance of the application.
* Publisher(s) may connect to any queue manager in the cluster
* Multiple 'discrete' applications can easily be supported on the same topics (each requiring their own administrative subscriptions on each queue manager)


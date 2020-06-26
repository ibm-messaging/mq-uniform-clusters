# mq-uniform-clusters

Uniform clusters are a specific pattern of an IBM MQ cluster that provides a highly available and horizontally scaled small collection of queue managers. These queue managers are configured almost identically, so that an application can interact with them as a single group.

**IBM MQ 9.1.x** introduced the ability to define a Uniform Cluster, This makes it easier to configure a set of matching queue managers and adds intelligent balancing of connected applications, ensuring messaging workload and processing is spread evenly across the queue managers.

## Demo

This [video on YouTube](https://www.youtube.com/watch?v=LWELgaEDGs0) takes you through a very simple demo of a Uniform Cluster containing three queue managers. Many of the scripts and configuration to run this demo can be found in 'demo/Linux' with help on running it [here](demo/Linux/usage.md).

More information on Uniform Clusters can be found [here](https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.pla.doc/q132720_.htm).

## License

The scripts are licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).

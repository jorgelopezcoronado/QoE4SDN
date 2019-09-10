# QoE4SDN

A repository for experimental evaluation of quality of experience (QoE) in software defined networking (SDN).

In order to create a [data-set](Predictions/Datasets) that allows obtaining a QoE model for prediction, experiments simulating different scenarios have been executed. The [Internet2](topology.pdf) topology has been simulated as the data-plane using [Containernet](https://github.com/containernet/containernet) and the [Onos SDN controller](https://onosproject.org). The experiments consist of asking users to configure an Onos host-to-host intent (data-path) and later to transmit a file between the hosts previously configured.

## Relevant QoE Parameters in SDN

The SDN parameters / attributes considered in the experimental results that show the need for considering parameters from all SDN layers for an accurate QoE prediction of SDN network services.

>Note that this list is non-exhaustive and can be augmented.

### Data-plane related QoE attributes

Parameters at this layer are related to the QoS attributes at the network layer (data-plane), which are traditionally considered for QoE prediction.

At this layer, we consider:

1. packet loss percentage: The percentage of packets not reaching their destination
2. average round-trip time (RTT): The average time the network packet (probes) take to reach their destination plus the time the acknowledgment is received back
3. minimum RTT: The minimum time the network packet (probes) take to reach their destination plus the time the acknowledgment is received back
4. maximum RTT: The maximum time the network packet (probes) take to reach their destination plus the time the acknowledgment is received back

Tehese parameters are collected using [path-stats.sh](MonitoringScripts/path-stats.sh) script.

### Control plane related QoE attributes

Parameters at this layer reflect the correct functioning of the control layer devices.
We consider:

1. path configuration delay: The time it takes for a data-path to be fully operational after being requested, collected using [path-delay.sh](MonitoringScripts/path-delay.sh)

2. controller latency: The time delay between a controller request and its response, collected using [controller-delay.sh](MonitoringScripts/controller-delay.sh)

### Application plane related QoE attributes

Parameters at this layer reflect the correct resource usage of the SDN architecture by the applications.

We consider:

1. matched packets’ percentage: The overall percentage of packets that are matched by the installed flow rules, collected using [matched_ratio](MonitoringScripts/matched_ratio)

2. unmatched rules’ percentage: The overall percentage of unmatched flow rules, collected using [unused_rule_percentage](MonitoringScripts/unused_rule_percentage)

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

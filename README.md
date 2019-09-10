# QoE4SDN

A repository for experimental evaluation of the Quality of Experience (QoE) assessment in the context of Software Defined Networking (SDN). Preliminary experimental results clearly demonstrate the necessity of considering QoE parameters, which are not taken into account in traditional networks. Dynamic network (re-) configuration requires monitoring and measuring attributes not only at the network level but also at the control and application planes.

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

## Experimental Results

A [data-set *V* containing 50 training examples](Prediction/Datasets/Data0/) was labelled reflecting the perceived QoE of a user performing the data-path use case. The data-set was labelled with a binary score for a simple assessment on the perceived good or bad QoE. The data-set has been created with a balanced label distribution, i.e., 23 bad training examples and 27
good ones.

Support Vector Machines (SVMs) have been used, in order to obtain the QoE model; two different kernels were considered: the linear and Gaussian kernel. Considering both Kernels, a grid search is performed for γ, and *C* parameters, using well established intervals, i.e., *C* ∈ {2<sup>−5</sup> , . . . , 2<sup>15</sup> }, and γ ∈ {2<sup>−15</sup> , . . . , 2<sup>3</sup> }. The SVM with the best cross-validation accuracy (best prediction) is then kept as the QoE model.

The highest cross-validation accuracy obtained is 100%; this result is rather unexpected, however, convenient for further studies. Using *V* the first and most interesting question this data-set is able to reply is if our initial hypothesis is correct, i.e., controller and application layer parameters are crucial for the correct prediction of QoE in SDN. Thus, in the next experiment the controller and application layer parameters have been removed from the training examples, and a new process to obtain the best SVM parameters has been executed; the cross-validation accuracy obtained is 82%, which supports our initial thesis.
Our experiments also show that when training an SVM with only a single parameter the lowest cross-validation accuracy is at least 74% for each of them, which indicates that all parameters are relevant ([see Table I](#table-i)). Another interesting conclusion drawn from our experiments is that if taking only the most relevant parameter of each layer (i.e., avg. RTT, data-path configuration delay, and unmatched rules’ percent- age) the cross-validation accuracy is 100%, which seems to indicate that all three layers are needed. We conjecture that the high correlation between the unmatched rules’ percentage and the user’s perceived QoE reflects how the application manages the SDN resources, at the same time, it reflects a potential high volume of data-plane traffic. Further, since the measurements of this parameter are taken from the controller, it indirectly measures the controller performance. Thus, such measurements allow monitoring the overall SDN framework state.

### Table I

|            | Avg. RTT| Max. RTT | Min. RTT | Pkt. Loss| Ctrl. Delay | DP Conf. Delay | Matched Pkt. % | Unmatched rules %|
|:----------:|:-------:|:--------:|:--------:|:--------:|:-----------:|:--------------:|:--------------:|:----------------:|
|**Accuracy**| 82%     | 78%      | 80%      | 76% | 76% | 82% | 96% | 74%|

Individual parameter cross-validation accuracy.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

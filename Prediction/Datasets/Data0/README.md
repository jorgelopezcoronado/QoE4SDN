# Dataset 0

In this folder, you can find the main dataset obtained through the experiments which consist of asking users to configure an Onos host-to-host intent (data-path) and later to transmit a file between the hosts previously configured.

To simulate different states of the network, various scenarios have been implemented: (*i*) degraded control plane, where the controller is either loaded by adding more than 10000 flow rules, or packets are stochastically dropped using the iptables filter; (*ii*) degraded data-plane, where different links of the data-plane are intermittently loaded using the [iperf](https://iperf.fr) utility; (*iii*) degraded control and data-plane, and finally (*iv*) unaffected SDN architecture, where no degradation is experienced. After a user performs an experiment at a given scenario, the feedback regarding their QoE is provided; the collected measurements at the time of the experiment get the associated label.

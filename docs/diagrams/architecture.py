#!/usr/bin/env python3
"""Multi-cloud hub-and-spoke architecture diagram.

Renders `architecture.png` depicting the exact topology provisioned by
`examples/dev`:

  * Azure Hub VNet (10.0.0.0/16)  — Azure Bastion + shared-services subnet
  * <-> bidirectional VNet peering <->
  * Azure Spoke VNet (10.1.0.0/16) — AKS (system/ai/app node pools) + ACR
  * AWS VPC (10.20.0.0/16)         — public/private subnets, IGW, single NAT GW

Author: Md Irshad — Senior Cloud & AI Platform Engineer

Usage:
    pip install -r requirements.txt   # needs the Graphviz "dot" binary
    python architecture.py            # writes architecture.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import AKS, ContainerRegistries
from diagrams.azure.network import VirtualNetworks, Subnets, VirtualNetworkGateways
from diagrams.azure.security import KeyVaults
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, InternetGateway, NATGateway

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.6",
    "splines": "spline",
}

with Diagram(
    "Multi-Cloud Hub-and-Spoke  (Azure + AWS)",
    filename="architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):

    with Cluster("Azure  —  Hub VNet  10.0.0.0/16"):
        bastion = VirtualNetworkGateways("Azure Bastion\nAzureBastionSubnet 10.0.0.0/27")
        shared = KeyVaults("shared-services 10.0.1.0/24\n(KeyVault svc endpoint)")

    with Cluster("Azure  —  Spoke VNet  10.1.0.0/16  (AKS)"):
        acr = ContainerRegistries("ACR\nAcrPull via kubelet MSI")
        with Cluster("AKS cluster (kubenet)"):
            system_pool = AKS("system pool\naks-system 10.1.0.0/22")
            ai_pool = AKS("ai / GPU pool\naks-ai 10.1.4.0/22")
            app_pool = AKS("app pool\naks-app 10.1.8.0/22")
        acr >> Edge(label="pull images", style="dashed", color="darkgreen") >> system_pool

    with Cluster("AWS  —  Independent Spoke VPC  10.20.0.0/16"):
        igw = InternetGateway("IGW")
        with Cluster("Public subnets\n10.20.0.0/24, 10.20.1.0/24"):
            pub = PublicSubnet("public (EKS elb tag)")
        with Cluster("Private subnets\n10.20.10.0/24, 10.20.11.0/24"):
            priv = PrivateSubnet("private (EKS internal-elb tag)")
        nat = NATGateway("single NAT GW")
        igw >> pub
        pub >> nat >> priv

    # Bidirectional hub <-> spoke VNet peering.
    bastion - Edge(label="VNet peering (bidirectional)", color="firebrick", style="bold") - system_pool

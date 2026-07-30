#!/usr/bin/env python3
"""Terraform delivery workflow diagram.

Renders `workflow.png`: Dev -> git push -> GitHub Actions (fmt-check ->
validate -> tflint) -> terraform init/plan/apply -> the four modules ->
Azure + AWS resources, with a remote-state note (Azure Blob / S3+DynamoDB).

Author: Md Irshad — Senior Cloud & AI Platform Engineer

Usage:
    pip install -r requirements.txt   # needs the Graphviz "dot" binary
    python workflow.py                # writes workflow.png
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.iac import Terraform
from diagrams.programming.flowchart import Action
from diagrams.azure.compute import AKS, ContainerRegistries
from diagrams.azure.network import VirtualNetworks
from diagrams.aws.network import VPC
from diagrams.azure.storage import BlobStorage
from diagrams.aws.database import Dynamodb

graph_attr = {"fontsize": "20", "bgcolor": "white", "pad": "0.6"}

with Diagram(
    "Terraform Delivery Workflow",
    filename="workflow",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):

    dev = Action("Dev\n(VSCode)")
    gh = Github("git push\nmain / PR")

    with Cluster("GitHub Actions  (.github/workflows/terraform.yml)"):
        fmt = GithubActions("fmt -check\n-recursive")
        validate = GithubActions("init -backend=false\n+ validate")
        lint = GithubActions("tflint\n--recursive")
        fmt >> validate >> lint

    with Cluster("terraform  examples/dev"):
        tf = Terraform("init / plan / apply")
        with Cluster("Modules"):
            m_vnet = Terraform("azure-vnet")
            m_aks = Terraform("azure-aks")
            m_bas = Terraform("azure-bastion")
            m_vpc = Terraform("aws-vpc")

    with Cluster("Remote state (choose one)"):
        state = BlobStorage("Azure Blob")
        lock = Dynamodb("S3 + DynamoDB lock")

    with Cluster("Cloud resources"):
        az_net = VirtualNetworks("Azure Hub/Spoke VNets")
        az_aks = AKS("AKS + node pools")
        az_acr = ContainerRegistries("ACR")
        aws = VPC("AWS VPC")

    dev >> gh >> fmt
    lint >> tf
    tf >> Edge(style="dashed", label="backend") >> state
    tf >> Edge(style="dashed") >> lock
    tf >> [m_vnet, m_aks, m_bas, m_vpc]
    m_vnet >> az_net
    m_aks >> [az_aks, az_acr]
    m_bas >> az_net
    m_vpc >> aws

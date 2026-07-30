# terraform-multicloud-hub-spoke

[![terraform](https://github.com/abdusirshad/terraform-multicloud-hub-spoke/actions/workflows/terraform.yml/badge.svg)](https://github.com/abdusirshad/terraform-multicloud-hub-spoke/actions/workflows/terraform.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.6-7B42BC?style=flat-square&logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Hub--Spoke-0078D4?style=flat-square&logo=microsoftazure)](https://azure.microsoft.com)
[![AWS](https://img.shields.io/badge/AWS-VPC-FF9900?style=flat-square&logo=amazonaws)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> A reusable **Terraform module library** for **multi-cloud (Azure + AWS) hub-and-spoke**
> networking with **AKS**. Four composable modules plus a `terraform validate`-clean
> `examples/dev` root that wires a hub VNet, an AKS spoke, Azure Bastion, and an
> EKS-ready AWS VPC together.

Author: **Md Irshad — Senior Cloud & AI Platform Engineer**

---

## Architecture

![Multi-cloud hub-and-spoke architecture](docs/diagrams/architecture.png)

Azure **Hub VNet `10.0.0.0/16`** (Azure Bastion + shared-services subnet) is
peered **bidirectionally** to the Azure **Spoke VNet `10.1.0.0/16`** running an
AKS cluster (system / ai-GPU / app node pools) with an ACR for zero-credential
image pulls. A separate, independent **AWS VPC `10.20.0.0/16`** (public/private
subnets, IGW, single NAT gateway, EKS-ready tags) is provisioned from the same
root plan — no cross-cloud VPN (out of scope).

```mermaid
flowchart TB
  subgraph AZ["Azure"]
    subgraph HUB["Hub VNet · 10.0.0.0/16"]
      BAS["Azure Bastion<br/>AzureBastionSubnet 10.0.0.0/27"]
      SS["shared-services 10.0.1.0/24<br/>(KeyVault svc endpoint)"]
    end
    subgraph SPOKE["Spoke VNet · 10.1.0.0/16"]
      subgraph AKS["AKS cluster (kubenet)"]
        SYS["system pool · aks-system 10.1.0.0/22"]
        AI["ai / GPU pool · aks-ai 10.1.4.0/22"]
        APP["app pool · aks-app 10.1.8.0/22"]
      end
      ACR["ACR — AcrPull via kubelet MSI"]
    end
    HUB <== "VNet peering (bidirectional)" ==> SPOKE
    ACR -. "pull images" .-> AKS
  end
  subgraph AWS["AWS — independent spoke"]
    subgraph VPC["VPC · 10.20.0.0/16"]
      IGW["Internet Gateway"] --> PUB["public 10.20.0.0/24, 10.20.1.0/24"]
      PUB --> NAT["single NAT gateway"] --> PRIV["private 10.20.10.0/24, 10.20.11.0/24"]
    end
  end
```

> Deep dive with all Mermaid diagrams and a per-module reference:
> [`docs/architecture.md`](docs/architecture.md).

<details>
<summary>ASCII fallback</summary>

```
                          ┌─────────────────────────────────────┐
                          │       Azure Hub VNet (10.0.0.0/16)   │
                          │  ┌──────────┐  ┌──────────────────┐  │
                          │  │  Azure   │  │  Shared services │  │
                          │  │ Bastion  │  │  subnet (KeyVault│  │
                          │  │  (jump)  │  │  svc endpoint)   │  │
                          │  └──────────┘  └──────────────────┘  │
                          └──────────┬──────────────────────────┘
                                     │ VNet peering (hub <-> spoke)
              ┌──────────────────────┴───────────────────────┐
              │                                               │
   ┌──────────▼────────────────────┐         ┌───────────────▼──────────────┐
   │ Azure Spoke VNet (10.1.0.0/16) │         │   AWS VPC (10.20.0.0/16)      │
   │  AKS cluster, kubenet:         │         │   public + private subnets    │
   │   - system pool (subnet 0)     │         │   IGW + single NAT gateway    │
   │   - ai/GPU pool   (subnet 1)   │         │   EKS-ready subnet tagging     │
   │   - app pool      (subnet 2)   │         │                               │
   │  ACR (AcrPull via MSI)         │         │                               │
   └────────────────────────────────┘         └───────────────────────────────┘
```

</details>

### Network topology / CIDR map

| Cloud | Network | CIDR | Subnet(s) | Purpose |
|-------|---------|------|-----------|---------|
| Azure | Hub VNet | `10.0.0.0/16` | `AzureBastionSubnet` `10.0.0.0/27`, `shared-services` `10.0.1.0/24` | Bastion + KeyVault svc endpoint |
| Azure | Spoke VNet | `10.1.0.0/16` | `aks-system` `10.1.0.0/22`, `aks-ai` `10.1.4.0/22`, `aks-app` `10.1.8.0/22` | AKS node-pool subnets (0/1/2) |
| AWS | VPC | `10.20.0.0/16` | public `10.20.0.0/24`,`10.20.1.0/24`; private `10.20.10.0/24`,`10.20.11.0/24` | IGW-routed / NAT-routed, EKS-ready |

---

## What's in this repo

```
terraform-multicloud-hub-spoke/
├── modules/
│   ├── azure-vnet/        # Hub/spoke VNet, subnet map, shared NSG, peering
│   │   ├── main.tf  variables.tf  outputs.tf  versions.tf  README.md
│   ├── azure-aks/         # AKS (kubenet), MSI x2, ACR RBAC, kubenet route table
│   │   ├── main.tf  variables.tf  outputs.tf  versions.tf  README.md
│   ├── azure-bastion/     # Azure Bastion host + static public IP
│   │   ├── main.tf  variables.tf  outputs.tf  versions.tf  README.md
│   └── aws-vpc/           # VPC, public/private subnets, route tables, NAT GW
│       ├── main.tf  variables.tf  outputs.tf  versions.tf  README.md
├── examples/
│   └── dev/               # Root module wiring all four modules together
│       ├── main.tf            # module composition
│       ├── variables.tf       # inputs
│       ├── outputs.tf         # selected outputs
│       ├── providers.tf       # azurerm + aws providers
│       ├── versions.tf        # terraform >= 1.6, azurerm ~> 4, aws ~> 5
│       ├── terraform.tfvars.example
│       ├── backend-azure.tf.example   # optional Azure Blob backend
│       └── backend-s3.tf.example      # optional S3 + DynamoDB backend
├── .github/workflows/terraform.yml    # fmt-check, init, validate, tflint
├── .tflint.hcl
├── .gitignore
├── LICENSE
└── README.md
```

Every file listed above exists in the repo — there are no stubs.

---

## Module library

| Module | Creates | Key inputs |
|--------|---------|------------|
| [`azure-vnet`](modules/azure-vnet/) | VNet, subnet map, shared workload NSG + rules, VNet peerings | `subnets`, `peerings`, `nsg_rules` |
| [`azure-aks`](modules/azure-aks/) | AKS (kubenet), control-plane + kubelet MSIs, AcrPull RBAC, kubenet route table | `node_pools`, `vnet_subnet_ids`, `acr_id` |
| [`azure-bastion`](modules/azure-bastion/) | Azure Bastion host + static Standard public IP | `subnet_id`, `sku` |
| [`aws-vpc`](modules/aws-vpc/) | VPC, public/private subnets across AZs, IGW, route tables, single NAT GW | `cidr_block`, `public_subnet_cidrs`, `private_subnet_cidrs` |

Each module ships its own `README.md` with the full input/output reference.

### Design highlights

- **Map-driven subnets and node pools** — add or remove subnets / node pools by
  editing a map input, never the module body.
- **Zero-credential image pulls** — AKS uses two user-assigned managed identities
  (control plane + kubelet); the kubelet identity is granted `AcrPull` on the ACR.
- **Kubenet route table** — created once and associated with every AKS subnet, the
  correct multi-subnet kubenet pattern.
- **EKS-ready AWS subnets** — tagged with `kubernetes.io/role/elb` and
  `kubernetes.io/role/internal-elb` so the VPC drops straight into an EKS install.
- **Reserved-subnet safety** — `AzureBastionSubnet` / `GatewaySubnet` are excluded
  from the workload-NSG association (Azure rejects restrictive NSGs there).

---

## Module dependency graph

How the `examples/dev` root wires the four modules together (from
[`examples/dev/main.tf`](examples/dev/main.tf)):

```mermaid
flowchart LR
  ROOT["examples/dev (root)"]
  ROOT --> HUBV["module.hub_vnet<br/>(azure-vnet)"]
  ROOT --> SPOKEV["module.spoke_vnet<br/>(azure-vnet)"]
  ROOT --> BAST["module.bastion<br/>(azure-bastion)"]
  ROOT --> AKSM["module.aks<br/>(azure-aks)"]
  ROOT --> VPCM["module.aws_vpc<br/>(aws-vpc)"]
  ROOT --> ACR["azurerm_container_registry.acr"]
  BAST -. "hub AzureBastionSubnet" .-> HUBV
  AKSM -. "spoke aks-* subnets" .-> SPOKEV
  AKSM -. "acr_id" .-> ACR
  HUBV <== "peering" ==> SPOKEV
```

Bastion depends on the hub `AzureBastionSubnet`; AKS depends on the three spoke
`aks-*` subnets and the ACR id. A live `terraform graph` render is available at
[`docs/diagrams/tf-graph.png`](docs/diagrams/tf-graph.png) (`make graph`).

---

## CI/CD workflow

![Terraform delivery workflow](docs/diagrams/workflow.png)

```mermaid
flowchart LR
  DEV["Dev (VSCode)"] --> PUSH["git push · PR to main"]
  PUSH --> FMT["fmt -check -recursive"]
  FMT --> VAL["init -backend=false + validate"]
  VAL --> LINT["tflint --recursive"]
  LINT --> PLAN["plan / apply (manual, credentialed)"]
  PLAN -. "remote state" .-> STATE["Azure Blob — or — S3 + DynamoDB"]
```

---

## Quickstart

> Prerequisites: Terraform **>= 1.6**. No cloud credentials are needed to
> `init -backend=false` + `validate` (the steps below). Credentials are only
> required for `plan` / `apply` against real clouds.

```bash
git clone https://github.com/abdusirshad/terraform-multicloud-hub-spoke.git
cd terraform-multicloud-hub-spoke/examples/dev

# Validate the example root (no backend, no credentials)
terraform init -backend=false
terraform validate
```

To actually plan/apply against your own clouds:

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your subscription/tenant/region

az login                       # Azure auth
export AWS_PROFILE=your-profile # AWS auth

terraform init                 # enable a backend first (see below) for shared state
terraform plan -out tfplan
terraform apply tfplan
```

### Remote state backends (optional)

`examples/dev` ships two backend templates. Rename **one** (drop the `.example`)
and supply its values at init time:

```bash
# Azure Blob
mv backend-azure.tf.example backend-azure.tf
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=sttfstatehubspoke" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/hub-spoke.tfstate"

# — or — AWS S3 + DynamoDB lock
mv backend-s3.tf.example backend-s3.tf
terraform init \
  -backend-config="bucket=tfstate-hub-spoke-<account-id>" \
  -backend-config="key=dev/hub-spoke.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=tf-state-lock"
```

A configuration may declare only one backend, so enable at most one template.

---

## How to run / verify

The same checks the CI workflow runs, locally:

```bash
# 1. Formatting (whole repo)
terraform fmt -check -recursive

# 2. Validate every module and the example root (no backend / credentials)
for d in modules/azure-vnet modules/azure-aks modules/aws-vpc \
         modules/azure-bastion examples/dev; do
  terraform -chdir="$d" init -backend=false -input=false
  terraform -chdir="$d" validate
done

# 3. Lint (optional — requires tflint)
tflint --init
tflint --recursive
```

This repo was verified locally with **Terraform v1.9.8** (azurerm v4.79.0,
aws v5.100.0): `terraform fmt -check -recursive` passes and all four modules
plus `examples/dev` return **"Success! The configuration is valid."**

---

## CI

[`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) runs on every
push / PR to `main`:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false` + `terraform validate` for each module and the
   example root
3. `tflint --recursive` with the azurerm + aws rulesets

It uses `hashicorp/setup-terraform` and `terraform-linters/setup-tflint`, needs no
cloud credentials, and is authored to pass on a public fork.

---

## Security notes

| Control | Implementation |
|---------|----------------|
| No long-lived AKS credentials | User-assigned managed identities for control plane and kubelet |
| Image pulls | `AcrPull` role on the kubelet identity — no registry passwords |
| API-server exposure | `api_server_authorized_ip_ranges` allow-list input |
| Private egress (AWS) | Private subnets route `0.0.0.0/0` via a NAT gateway only |
| Operator access | Azure Bastion jump-host; no public IPs on workload nodes |
| State & secrets | State files, `*.tfvars`, `*.pem/.key`, `.env` excluded via `.gitignore`; backends configured out-of-band |

No secrets are committed — `terraform.tfvars.example` ships placeholders only.

---

## What this demonstrates

- **Hub-and-spoke** network segmentation with bidirectional VNet peering.
- **Multi-cloud** delivery (Azure + AWS) from a single Terraform root.
- **Reusable, map-driven modules** — subnets/node pools change via map inputs, not module edits.
- **MSI / ACR RBAC** — two user-assigned identities; `AcrPull` for zero-credential image pulls.
- **Remote state** — Azure Blob or S3 + DynamoDB backend templates.
- **Policy as code** — `tflint` (azurerm + aws rulesets) enforced in CI.

---

## Diagrams

The diagrams above are generated as code with the
[`diagrams`](https://diagrams.mingrammer.com/) (mingrammer) library and Graphviz.

```bash
make diagrams   # -> docs/diagrams/architecture.png + workflow.png (Python + Graphviz)
make graph      # -> docs/diagrams/tf-graph.png (terraform init + Graphviz)
```

Source: [`docs/diagrams/architecture.py`](docs/diagrams/architecture.py),
[`docs/diagrams/workflow.py`](docs/diagrams/workflow.py). Mermaid versions
(rendered inline by GitHub) live in this README and
[`docs/architecture.md`](docs/architecture.md).

---

## License

[MIT](LICENSE) © Md Irshad

# Module: `aws-vpc`

Creates an AWS VPC with public and private subnets spread across availability
zones, an internet gateway, route tables, and an optional single NAT gateway for
private-subnet egress. Subnets are tagged with the standard
`kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` tags so the VPC is
EKS-ready.

## Behaviour

- `public_subnet_cidrs` / `private_subnet_cidrs` are lists; subnet `i` lands in
  `azs[i % length(azs)]`, so you control the AZ spread purely through input order.
- A single NAT gateway is created (cost-conscious default) in the first public
  subnet and is only created when there is at least one public **and** one private
  subnet and `enable_nat_gateway = true`.
- The public route table sends `0.0.0.0/0` to the internet gateway; the private
  route table sends `0.0.0.0/0` to the NAT gateway when present.

## Usage

```hcl
module "aws_vpc" {
  source     = "../../modules/aws-vpc"
  name       = "vpc-dev-spoke"
  cidr_block = "10.20.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

  enable_nat_gateway = true
  tags               = { environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix for the VPC and children. |
| `cidr_block` | `string` | — | Primary VPC CIDR. |
| `azs` | `list(string)` | — | Availability zones to spread subnets across. |
| `public_subnet_cidrs` | `list(string)` | `[]` | Public subnet CIDRs. |
| `private_subnet_cidrs` | `list(string)` | `[]` | Private subnet CIDRs. |
| `enable_nat_gateway` | `bool` | `true` | Create a single NAT gateway. |
| `enable_dns_hostnames` | `bool` | `true` | Enable DNS hostnames on the VPC. |
| `tags` | `map(string)` | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID. |
| `vpc_cidr_block` | VPC primary CIDR. |
| `public_subnet_ids` | List of public subnet IDs. |
| `private_subnet_ids` | List of private subnet IDs. |
| `internet_gateway_id` | Internet gateway ID (or null). |
| `nat_gateway_id` | NAT gateway ID (or null). |

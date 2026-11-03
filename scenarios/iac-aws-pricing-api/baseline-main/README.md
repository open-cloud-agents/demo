# pricing-api infrastructure

Terraform for the Harbrook Retail pricing API platform in AWS (`eu-west-1`).

The pricing API serves current shelf and promotional prices to the storefront and
to the in-store handhelds. It runs as a Fargate service behind a public
application load balancer, with prices held in a PostgreSQL instance.

## What is in here

| File | Contents |
| --- | --- |
| `terraform.tf` | Backend, provider and version constraints |
| `vpc.tf` | VPC, subnets, internet gateway, public routing |
| `security-groups.tf` | Load balancer and task security groups and their rules |
| `load-balancer.tf` | ALB, target group and listener |
| `ecs.tf` | ECS cluster, task definition and service |
| `iam.tf` | Task execution role |
| `rds.tf` | Database subnet group and PostgreSQL instance (RDS manages the master password) |
| `s3.tf` | Load balancer access log bucket |

Subnets are fanned out over the first two availability zones in the region.
Public subnets carry the load balancer and the API tasks; private subnets exist
for the database subnet group. There is no NAT gateway - tasks reach the internet
via a public IP.

## Working with it

```
make init          # remote state in S3
make init-offline  # no backend, for a quick local check
make validate
make plan
make fmt
```

`make plan` runs with `-refresh=false` and placeholder credentials so it can be
run without access to the live account. It swaps in a local backend for the
duration, so no state is read or written. Availability zones are listed
explicitly in `locals.tf` rather than looked up, so a plan makes no API calls at
all.

## State

Remote state lives in `xd-tfstate-838029585209` under the key
`estates/<name_suffix>/terraform.tfstate`, which the workflows pass at `init`. Locking uses the S3 native lock file, so there
is no DynamoDB table to keep in step.

## Conventions

- One file per AWS service, hyphenated filenames.
- Resource names are lowercase strings of the form `<type>-pricing-api-<role>-<suffix>`,
  where `<suffix>` is `var.name_suffix`: one estate per suffix.
- Every resource that supports tags carries a single `Name` tag matching its
  name argument.

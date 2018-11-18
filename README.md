# Vault AWS Module

This repo contains a Module for how to deploy a [Vault](https://www.vaultproject.io/) cluster on 
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Vault is an open source tool for managing
secrets. By default, this Module uses [Consul](https://www.consul.io) as a [storage 
backend](https://www.vaultproject.io/docs/configuration/storage/index.html). 

![Vault architecture](https://github.com/hashicorp/terraform-aws-vault/blob/master/_docs/architecture.png?raw=true)

## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such 
as a database or server cluster. Each Module is created primarily using [Terraform](https://www.terraform.io/), 
includes automated tests, examples, and documentation, and is maintained both by the open source community and 
companies that provide commercial support. 

Instead of having to figure out the details of how to run a piece of infrastructure from scratch, you can reuse 
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, 
you can leverage the work of the Module community and maintainers, and pick up infrastructure improvements through
a version number bump.
 
 
## How do you use this Module?

1. Create an AMI that has Vault and Consul installed
   We achieve segregration trough SELinux and systemd

   If you are just experimenting with this Module, you may find it more convenient to use one of our official public AMIs:
   - [Latest Ubuntu 16 AMIs]().
   - [Latest Amazon Linux AMIs]().
   
   **WARNING! Do NOT use these AMIs in your production setup. In production, you should build your own AMIs in your 
     own AWS account.**

1. Deploy that AMI across an Auto Scaling Group in a private subnet using the Terraform. 


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines]() for instructions.

## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, 
along with the changelog, in the [Releases Page](../../releases). 

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a 
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, 
MINOR, and PATCH versions on each release to indicate any incompatibilities. 

## License

MIT

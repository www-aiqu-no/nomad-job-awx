# Ansible Tower (awx) on Nomad
This is a basic job-definition for deploying
[awx](https://github.com/ansible/awx) to your
[nomad](https://www.nomadproject.io/) cluster
([HashiCorp](https://www.hashicorp.com/))

## Deployment
I use [terraform](https://terraform.io/) for managing nomad-jobs, and hence the
job-definition is written in [hcl-format](https://github.com/hashicorp/hcl)

All tasks are defined in a single "group" (meaning they will be scheduled to run
on the same host). If you split the tasks, then the interpolated variables will
not work, and need to be re-defined

## Disclaimer
To run in a production environment, you should modify the file to suit your
environment. Examples:

- Increase increase job resources (cpu, memory, ..)
- Integrate with [consul](https://www.consul.io/)
- Integrate with [vault](https://www.vaultproject.io)
- Persist storage properly for database
- Use versioned container images
- Use private container repo
- configure dynamic addressing (example: [envoy](https://www.envoyproxy.io/))

## TODO
- Add [consul template](https://github.com/hashicorp/consul-template) &
terraform integration

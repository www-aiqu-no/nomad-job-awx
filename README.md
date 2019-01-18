# NOMAD Ansible Tower (awx)
This is a basic [nomad](https://www.nomadproject.io/) job-definition for testing [awx](https://github.com/ansible/awx)

# Deployment
I use [terraform](https://terraform.io/) for managing nomad-jobs, and hence the job definition is written in
[hcl-format](https://github.com/hashicorp/hcl)

# Disclaimer
To run in a production environment, you should modify the file to suit your
environment; e.g. integrate with [consul](https://www.consul.io/) and
[vault](https://www.vaultproject.io), persist storage properly for database,
use versioned docker images/private repo, increase resources,
configure dynamic addressing (example: [envoy](https://www.envoyproxy.io/))),
and so on..

# TODO
- Use [consul template](https://github.com/hashicorp/consul-template)

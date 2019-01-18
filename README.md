# NOMAD Ansible Tower (awx)
This is a basic [nomad](https://www.nomadproject.io/) job-definition for testing [awx](https://github.com/ansible/awx)

# Deployment
I use [terraform](https://terraform.io/) for managing nomad-jobs, and hence the job definition is written in
[hcl-format](https://github.com/hashicorp/hcl)

# Disclaimer
To run in a production environment, you should modify the file to suit your
environment. Examples:

- Increase increase job resources (cpu, memory, ..)
- Integrate with [consul](https://www.consul.io/)
- Integrate with [vault](https://www.vaultproject.io)
- Persist storage properly for database
- Use versioned container images
- Use private container repo
- configure dynamic addressing (example: [envoy](https://www.envoyproxy.io/)))

# TODO
- Add [consul template](https://github.com/hashicorp/consul-template) &
terraform integration

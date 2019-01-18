# NOMAD Ansible Tower (awx)

This is a basic [nomad](https://www.nomadproject.io/) job-definition for testing [awx](https://github.com/ansible/awx)

I use [terraform](https://terraform.io/) for managing nomad-jobs, and hence the job definition is written in
hcl-format

To run in a production environment, you should modify the file to suit your
environment

# TODO
- Use [consul template](https://github.com/hashicorp/consul-template)

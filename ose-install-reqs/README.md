# ose-install-reqs

A very basic ansible playbook to be run prior to installing OpenShift Enterprise on a RHEL 7.X server. The playbook checks for the 
basic requirements needed to install an OpenShift Enterprise v3 system.

# To run the playbook

- Install ansible.
- Clone this git repo.
- Edit the hosts file and update the names and variable defintions accordingly.
- Run: `ansible-playbook site.yaml -i hosts`

#!/bin/bash
basic_checks () {
if ! which ansible >/dev/null 2>&1 ; then
  echo "Error: Ansible is either not in your path or you need to install atomic-openshift-utils"
  exit
fi
if ! ansible -m ping all > /dev/null 2>&1 ; then
  echo "ping failed"
  exit
fi
}
#
show_help () {
cat <<-HELP
${0} [ --etcd | --help ]
    --etcd - Use this if you have etcd nodes
    --help - prints this screen
HELP
exit
}
[[ $1 = "--help" ]] && show_help
[[ $1 = "--etcd" ]] && etcd=true

basic_checks
ansible all -m shell -a 'systemctl stop atomic-openshift-master atomic-openshift-node docker || true'
ansible all -m shell -a 'systemctl disable atomic-openshift-master atomic-openshift-node docker || true'

ansible all -m shell -a 'yum remove -y openshift* atomic* openvswitch openshift-* atomic-* || true'
 
ansible all -m shell -a 'rm -rf /etc/origin/* || true '
ansible all -m shell -a 'rm -rf /etc/sysconfig/atomic* || true '
 
ansible all -m shell -a 'rm -rf /root/.kube || true'
ansible all -m shell -a 'rm -rf /var/lib/origin || true'

ansible all -m shell -a 'rm -rf /var/lib/etcd || true'
ansible all -m shell -a 'rm -rf /etc/etcd || true'
ansible all -m shell -a 'rm -rf /etc/openvswitch || true'

if [ ${etcd:=false} = "true" ]; then
  echo "yes"
  ansible etcd -m shell -a 'yum remove -y etcd || true'
  ansible etcd -m shell -a 'rm -rf /var/lib/etcd || true'
  ansible etcd -m shell -a 'rm -rf /etc/etcd || true'
fi
 
ansible all -m yum -a 'name=atomic-openshift-utils state=latest'
ansible all -m yum -a 'name=atomic-openshift-excluder state=latest'
ansible all -m yum -a 'name=atomic-openshift-docker-excluder state=latest'
ansible all -m shell -a 'atomic-openshift-excluder unexclude'
echo "You'll probably want to reboot everything and rerun this script"
##
##

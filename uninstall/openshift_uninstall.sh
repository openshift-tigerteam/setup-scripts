#!/bin/bash
[[ $1 = "--etcd" ]] && etcd=true

ansible all -m shell -a 'yum remove -y openshift* atomic* openvswitch'
 
ansible all -m shell -a 'rm -rf /etc/origin/* || true '
ansible all -m shell -a 'rm -rf /etc/sysconfig/atomic* || true '
 
ansible all -m shell -a 'rm -rf /root/.kube || true'
ansible all -m shell -a 'rm -rf /var/lib/origin || true'
 
if [ ${etcd:=false} = "true" ]; then
  echo "yes"
  ansible etcd -m shell -a 'yum remove -y etcd'
  ansible etcd -m shell -a 'rm -rf /var/lib/etcd || true'
  ansible etcd -m shell -a 'rm -rf /etc/etcd || true'
fi
 
ansible all -m yum -a 'name=atomic-openshift-utils state=latest'
##
##

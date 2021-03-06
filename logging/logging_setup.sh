#!/bin/bash
#
kibanaurl=${KIBANA_HOSTNAME}
pmasterurl=${PUBLIC_MASTERURL}
pmasterurlport=${PUBLIC_MASTERURL_PORT}
masterurl=${MASTERURL}
masterurlport=${MASTERURL_PORT}
ocpver=${OPENSHIFT_VERSION}
labelnodes=${LABEL_NODES}
ocpuser=$(echo -n $(oc whoami))
#
presetupcheck () {
  errcount=0
  [[ -z ${kibanaurl} ]]  && errcount=$[ ${errcount} + 1 ]
  [[ -z ${pmasterurl} ]] && errcount=$[ ${errcount} + 1 ]
  [[ -z ${masterurl} ]]  && errcount=$[ ${errcount} + 1 ]
  [[ -z ${ocpver} ]]     && errcount=$[ ${errcount} + 1 ]
  [[ -z ${masterurlport} ]]     && errcount=$[ ${errcount} + 1 ]
  [[ -z ${pmasterurlport} ]]     && errcount=$[ ${errcount} + 1 ]
  if [ ${errcount} -ne  0 ]; then
    echo "Please set the env variables"
    echo "example:"
    echo "	export KIBANA_HOSTNAME=kibana.cloudapps.example.com"
    echo "	export PUBLIC_MASTERURL=ose3-master.example.com"
    echo "	export MASTERURL=ose3-master.example.com"
    echo "	export LABEL_NODES=true"
    echo "	export OPENSHIFT_VERSION=3.4"
    echo "	export PUBLIC_MASTERURL_PORT=8443"
    echo "	export MASTERURL_PORT=8443"
    exit
  fi
  if [ ${ocpuser:=null} != "system:admin" ]; then
    echo "This can only be ran by an OpenShift admin"
    exit
  fi
}
#
setup () {
echo "WARNING: This script is experemental and not fully tested. Do you want to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No )  exit;;
    esac
done

#oc create -n openshift -f /usr/share/openshift/examples/infrastructure-templates/enterprise/logging-deployer.yaml

oadm new-project logging --node-selector=""

oc project logging

oc new-app logging-deployer-account-template

oc secrets new logging-deployer nothing=/dev/null

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: logging-deployer
secrets:
- name: logging-deployer
API

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aggregated-logging-kibana
secrets:
- name: aggregated-logging-kibana
API

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aggregated-logging-elasticsearch
secrets:
- name: aggregated-logging-elasticsearch
API

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aggregated-logging-fluentd
secrets:
- name: aggregated-logging-fluentd
API

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aggregated-logging-curator
secrets:
- name: aggregated-logging-curator
API

oadm policy add-cluster-role-to-user oauth-editor system:serviceaccount:logging:logging-deployer
oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd 
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:logging:aggregated-logging-fluentd
oadm policy add-cluster-role-to-user rolebinding-reader system:serviceaccount:logging:aggregated-logging-elasticsearch

oc create configmap logging-deployer \
   --from-literal kibana-hostname=${kibanaurl} \
   --from-literal public-master-url=https://${pmasterurl}:${pmasterurlport} \
   --from-literal es-cluster-size=1 

oc new-app logging-deployer-template \
             --param KIBANA_HOSTNAME=${kibanaurl} \
             --param ES_CLUSTER_SIZE=1 \
             --param PUBLIC_MASTER_URL=https://${pmasterurl}:${pmasterurlport} \
             --param IMAGE_PREFIX="registry.access.redhat.com/openshift3/" \
             --param MASTER_URL=https://${masterurl}:${masterurlport} \
             --param IMAGE_VERSION=v${ocpver} \
             --param MODE=install

if ${labelnodes=:false} ; then
   oc label node --all logging-infra-fluentd=true
else
   echo "You elected to not label your nodes...you may have to do this manually!"
fi
cat <<-EOF
Add 'metricsPublicURL: "${kibanaurl}"' to /etc/origin/master/master-config.yaml ...it should look like this one

[root@ose3-master ~]# grep -i ${kibanaurl} -B10 /etc/origin/master/master-config.yaml
  masterPublicURL: https://ose3-master.example.com:8443
  publicURL: https://ose3-master.example.com:8443/console/
  servingInfo:
    bindAddress: 0.0.0.0:8443
    bindNetwork: tcp4
    certFile: master.server.crt
    clientCA: ""
    keyFile: master.server.key
    maxRequestsInFlight: 0
    requestTimeoutSeconds: 0
  metricsPublicURL: "https://hawkular.cloudapps.example.com/hawkular/metrics" 
  loggingPublicURL: "https://${kibanaurl}"

THEN run the following:

	systemctl restart atomic-openshift-master.service 
EOF
sleep 5
echo "===========DONE=============="
};
#
cleanup () {
echo "Cleaning up logging setup..."
sleep 5
oc project logging
oc delete all --selector logging-infra=kibana
oc delete all --selector logging-infra=fluentd
oc delete all --selector logging-infra=elasticsearch
oc delete all --selector logging-infra=curator
oc delete all,sa,oauthclient --selector logging-infra=support
oc delete all,sa,oauthclient --selector logging-infra=support
oc delete secret logging-fluentd logging-elasticsearch logging-es-proxy logging-kibana logging-kibana-proxy logging-kibana-ops-proxy
oc delete oauthclients kibana-proxy
oc delete templates --all -n logging
oc delete ds logging-fluentd -n logging
oc delete pods --all -n logging --now
oc delete clusterrole oauth-editor daemonset-admin rolebinding-reader -n logging
oc project default
sleep 2
oc delete project logging
};
#
presetupcheck
#
opt=$1
case $opt in
        '--setup')
                setup
                exit
                ;;
        '--cleanup')
		cleanup
                exit
                ;;
        *)
                echo "Deploy Logging"
                echo "Usage: $0 {--setup|--cleanup|--help}"
                echo "	--setup   : Setup and Configure logging"
                echo "	--cleanup : Use this to cleanup and start over"
                echo "	--help    : This help page"
                exit
                ;;
esac
##
##

#!/bin/bash
#
hawkurl=${HAWKULAR_HOSTNAME}
ocpuser=$(echo -n $(oc whoami))
imagever=${HAWKULAR_IMAGE_VER}
masterurl=${OSE_MASTER_URL}
#
presetupcheck () {
  if [ -z ${hawkurl} ]; then
    echo "Please set the env variable HAWKULAR_HOSTNAME"
    echo "example:"
    echo "	export HAWKULAR_HOSTNAME=hawkular.cloudapps.example.com"
    echo "	export HAWKULAR_IMAGE_VER=3.4"
    echo "	export OSE_MASTER_URL=https://ose3-master.example.com:8443"
    exit
  fi
  if [ ${ocpuser:=null} != "system:admin" ]; then
    echo "This can only be ran by an OpenShift admin"
    exit
  fi
}
#
setup () {
echo "Starting cluster metrics setup..."
[[ ! -f /usr/share/openshift/examples/infrastructure-templates/enterprise/metrics-deployer.yaml ]] && echo "FATAL: Metrics Deployer File not found!" && exit 254
oc project openshift-infra
echo "Cleaning up environment...it's okay if you see errors here"
oc delete all,sa,templates,secrets,pvc --selector="metrics-infra"
oc delete sa,secret metrics-deployer
oc secrets new metrics-deployer nothing=/dev/null
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster
oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API

cd ~

cp /usr/share/openshift/examples/infrastructure-templates/enterprise/metrics-deployer.yaml .

[[ ! -f ~/metrics-deployer.yaml ]] && echo "FATAL: Metrics Deployer File not found!" && exit 254

oc new-app --as=system:serviceaccount:openshift-infra:metrics-deployer \
-f metrics-deployer.yaml \
-p HAWKULAR_METRICS_HOSTNAME=${hawkurl} \
-p USE_PERSISTENT_STORAGE=false -p MASTER_URL=${masterurl} \
-p IMAGE_PREFIX=openshift3/ -p IMAGE_VERSION=v${imagever}

oc adm policy add-role-to-user view system:serviceaccount:openshift-infra:hawkular -n openshift-infra

cat <<-EOF
Use "oc get pods -n openshift-infra --watch" to make sure the pods come up

Then add 'metricsPublicURL: "${hawkurl}/hawkular/metrics"' to /etc/origin/master/master-config.yaml ...it should look like this one

[root@ose3-master ~]# grep -i hawkular -B10 /etc/origin/master/master-config.yaml
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
  metricsPublicURL: "https://${hawkurl}/hawkular/metrics" 

THEN run the following:

	systemctl restart atomic-openshift-master.service 
EOF
sleep 5
echo "===========DONE=============="
};
#
cleanup () {
echo "Cleaning up cluster metrics setup..."
sleep 5
oc project openshift-infra
oc delete all --all
oc delete templates --all
oc delete secrets `oc get secrets | egrep 'metrics|hawk|heap' | awk '{print $1}'`
oc delete sa hawkular cassandra heapster metrics-deployer
oc delete all,sa,templates,secrets,pvc --selector="metrics-infra"
oc delete sa,secret metrics-deployer
oc project default
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
                echo "Deploy Metrics"
                echo "Usage: $0 {--setup|--cleanup|--help}"
                echo "	--setup   : Setup and Configure Metrics"
                echo "	--cleanup : Use this to cleanup and start over"
                echo "	--help    : This help page"
                exit
                ;;
esac
##
##

#!/bin/bash
#
hawkurl=${HAWKULAR_HOSTNAME}
ocpuser=$(echo -n $(oc whoami))
#
presetupcheck () {
  if [ -z ${hawkurl} ]; then
    echo "Please set the env variable HAWKULAR_HOSTNAME"
    echo "example:"
    echo "	export HAWKULAR_HOSTNAME=hawkular.cloudapps.example.com"
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
sleep 5
oc project openshift-infra

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API

oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer

oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster

oc secrets new metrics-deployer nothing=/dev/null

cd ~

cp /usr/share/openshift/examples/infrastructure-templates/enterprise/metrics-deployer.yaml .

oc process -f metrics-deployer.yaml -v IMAGE_PREFIX=openshift3/,IMAGE_VERSION=latest,HAWKULAR_METRICS_HOSTNAME=${hawkurl},USE_PERSISTENT_STORAGE=false | oc create -f -

cat <<-EOF
Add 'metricsPublicURL: "${hawkurl}/hawkular/metrics"' to /etc/origin/master/master-config.yaml ...it should look like this one

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

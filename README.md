# Setup Scripts
Various Setup scripts

## Metrics Setup
In [here](metrics) you'll find resources to setup metrics post-installation

`metrics_setup.sh`

You first need to export `HAWKULAR_HOSTNAME`
```
export HAWKULAR_HOSTNAME=hawkular.cloudapps.example.com
```

Next, you can run the setup
```
./metrics_setup.sh --setup
```

There are 3 options currently
```
Usage: ./metrics_setup.sh {--setup|--cleanup|--help}
	--setup   : Setup and Configure Metrics
	--cleanup : Use this to cleanup and start over
	--help    : This help page
```

## Logging
In [here](logging) you'll find resources to setup log aggragation post-installation.

*EXPEREMENTAL! NOT FULLY TESTED YET - USE AT YOUR OWN RISK*

You first need to export the following
```
export KIBANA_HOSTNAME=kibana.cloudapps.example.com
export PUBLIC_MASTERURL=ose3-master.example.com
export MASTERURL=ose3-master.example.com
export FLUENTD_REPLICAS=2
export OPENSHIFT_VERSION=3.3.0
```

Then you can run the setup
```
./logging_setup.sh --setup
```

The options currently
```
Usage: $0 {--setup|--cleanup|--help}"
	--setup   : Setup and Configure logging"
	--cleanup : Use this to cleanup and start over"
	--help    : This help page"
```

## Uninstall
In [here](uninstall) you'll find an uninstall script that you'll need to run along with the uninstaller ansible-playbook 

```
./openshift_uninstall.sh
```
If you are running multi-master
```
./openshift_uninstall.sh --etcd
```

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
	--setup   : Setup and Configure Metrics for Rogers
	--cleanup : Use this to cleanup and start over
	--help    : This help page
```

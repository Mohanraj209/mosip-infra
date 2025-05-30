#!/bin/bash
# Installs kafka
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=kafka
CHART_VERSION=26.11.4
UI_CHART_VERSION=0.7.1

echo Create $NS namespace
kubectl create ns $NS

function installing_kafka() {
  echo Istio label
  kubectl label ns $NS istio-injection=enabled --overwrite

  echo Updating helm repos
  helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update

  echo Installing kafka
  helm -n $NS install kafka bitnami/kafka -f values.yaml --wait --version $CHART_VERSION

  echo Installing kafka-ui
  helm -n $NS install kafka-ui kafka-ui/kafka-ui -f ui-values.yaml --wait --version $UI_CHART_VERSION

  KAFKA_UI_HOST=$(kubectl get cm global -o jsonpath={.data.mosip-kafka-host})
  KAFKA_UI_NAME=kafka-ui

  echo Install istio addons
  helm -n $NS install istio-addons mosip/istio-addons --set kafkaUiHost=$KAFKA_UI_HOST --set installName=$KAFKA_UI_NAME -f istio-addons-values.yaml

  echo Installed kafka and kafka-ui services
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_kafka   # calling function

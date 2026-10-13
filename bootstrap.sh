#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-todoapp}"
APP_IMAGE="${APP_IMAGE:-todoapp:local}"
MYSQL_DATABASE="tododb"

: "${MYSQL_ROOT_PASSWORD:?Set MYSQL_ROOT_PASSWORD before running bootstrap.sh}"
: "${MYSQL_USER:?Set MYSQL_USER before running bootstrap.sh}"
: "${MYSQL_PASSWORD:?Set MYSQL_PASSWORD before running bootstrap.sh}"
SECRET_KEY="${SECRET_KEY:-$(python -c 'import secrets; print(secrets.token_urlsafe(50))')}"

if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config cluster.yml
fi

kubectl apply -f .infrastructure/namespace.yml
kubectl create secret generic mysql-credentials \
  --namespace mysql \
  --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  --from-literal=MYSQL_USER="$MYSQL_USER" \
  --from-literal=MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic app-db-credentials \
  --namespace todoapp \
  --from-literal=NAME="$MYSQL_DATABASE" \
  --from-literal=USER="$MYSQL_USER" \
  --from-literal=PASSWORD="$MYSQL_PASSWORD" \
  --from-literal=HOST=mysql-0.mysql.mysql.svc.cluster.local \
  --from-literal=SECRET_KEY="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

docker build -t "$APP_IMAGE" ./src
kind load docker-image "$APP_IMAGE" --name "$CLUSTER_NAME"

kubectl apply -f statefulSet.yml
kubectl rollout status statefulset/mysql --namespace mysql --timeout=10m
kubectl apply -f .infrastructure/deployment.yml
kubectl apply -f .infrastructure/clusterIp.yml
kubectl apply -f .infrastructure/nodeport.yml
kubectl rollout status deployment/todoapp --namespace todoapp --timeout=5m

# Validation instructions

## Prerequisites

Install Docker, `kind`, `kubectl`, and Python. Run the commands below from the
repository root in a Bash-compatible shell.

## Deploy

Set credentials for the MySQL root account and application user. Use a strong
password and keep these values out of source control.

```bash
export MYSQL_ROOT_PASSWORD='replace-with-a-strong-root-password'
export MYSQL_USER='todoapp'
export MYSQL_PASSWORD='replace-with-a-strong-application-password'
bash bootstrap.sh
```

`bootstrap.sh` creates the kind cluster from `cluster.yml` if it does not
already exist, builds and loads the application image, creates the namespaces
and Secrets, and deploys MySQL and the application.

## Verify resources and database

```bash
kubectl get statefulset,pods,services,pvc --namespace mysql
kubectl get deployment,pods,services --namespace todoapp
kubectl rollout status statefulset/mysql --namespace mysql
kubectl rollout status deployment/todoapp --namespace todoapp
kubectl exec --namespace mysql mysql-0 -- sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"'
```

Confirm that all three `mysql` pods are Ready and have their own bound
`mysql-data` claims. The application Secret uses `NAME`, `USER`, `PASSWORD`,
and `HOST`; the host resolves to the ordinal-zero database pod,
`mysql-0.mysql.mysql.svc.cluster.local`.

## Open the application

The kind configuration maps NodePort `30007` to the host. Visit
<http://localhost:30007>. Alternatively, use port forwarding:

```bash
kubectl port-forward --namespace todoapp service/todoapp-service 8080:80
```

Then visit <http://localhost:8080>.

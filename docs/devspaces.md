# Deploy and configure External Secrets Manager on OpenShift Dev Spaces

## Prerequisites
* OpenShift 4.12+ cluster

## Steps

1. Login to OpenShift
```
oc login -u <username> -p <password> <cluster_url>
```

2. Run the script below to install OpenShift Gitops
```
git clone https://github.com/tosin2013/sno-quickstarts.git
cd sno-quickstarts/gitops
./deploy.sh
```

3. Configure Cluster 
```
oc create -f apps/device-edge-demos/cluster-config.yaml
```

![20230821122544](https://i.imgur.com/SALDxq0.png)

4. Access Dev Spaces URL and login 
5. Create a new space
`https://github.com/tosin2013/external-secrets-manager.git`
![20230904104952](https://i.imgur.com/ozdTVVk.png)

![20230821125119](https://i.imgur.com/WuWYqA6.png)

Edit `inventories/controller/group_vars/all.yml` and update the following variables:
```
# openshift_token: 12345678
# openshift_url: https://api.ocp4.example.com:6443
# insecure_skip_tls_verify: true

install_vault: true
push_secrets: false 
vault_secrets_init: false # Set to true to initialize vault secrets


# Vault vaules
localClusterDomain: apps.foo.cluster.com
hubClusterDomain: apps.hub.example.com
clusterDomain: foo.example.com

# Vault Helm chart version Change to vaule below
vault_helm_version: v0.19.0 # default v0.25.0

```
![20230904162438](https://i.imgur.com/DGfiJ0y.png)

6. Run the playbook to install vault and external secrets manager
```
ansible-playbook install-vault.yaml --extra-vars "@inventories/controller/group_vars/all.yml"
```
# External Secrets Manager
This is a simple example of how to use external secrets manager to manage secrets in a Kubernetes cluster. It uses Hashicorp Vault as the secrets manager and external-secrets to manage the secrets in the cluster. Ansible will be used to deploy and configure the vault and external secret secrets manager.

## Prerequisites
- A OpenShift Cluster
- Ansible Navigator

## Usage
**Deploy and configure vault**
```
$ ansible-navigator run vault.yaml  --extra-vars "install_vault=true" \
 --vault-password-file $HOME/.vault_password -m stdout 
```

**Copy template from /vars folder**
*For AWS Secrets*
```
$ cp vars/values-secret.aws.yaml.template ~/values-secret.yaml
```
*For Git Credentials*
```
$ cp vars/values-secret.git.yaml.template ~/values-secret.yaml
```
*For Quay Secret*
```
$ cp vars/values-secret.quay.yaml.template ~/values-secret.yaml
```

**Push secrets and configure secrets**
```
$ ansible-navigator run push-secrets.yaml --extra-vars "vault_push_secrets=true"   --extra-vars "vault_secrets_init=true" \
 --vault-password-file $HOME/.vault_password -m stdout 
```


**Delete and remove vault and external-secrets**
```
$ ansible-navigator run vault.yaml  --extra-vars "install_vault=false" \
 --vault-password-file $HOME/.vault_password -m stdout 
```

## For Developers
[Developers Guide](docs/developers.md)

## References
- [External Secrets](https://external-secrets.io/latest/)
- [Vault](https://www.vaultproject.io/)
- [Industrial Edge](https://github.com/validatedpatterns/industrial-edge)
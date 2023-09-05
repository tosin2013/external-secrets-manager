# External Secrets Manager
This is a simple example of how to use external secrets manager to manage secrets in a Kubernetes cluster. It uses Hashicorp Vault as the secrets manager and external-secrets to manage the secrets in the cluster. Ansible will be used to deploy and configure the vault and external secret secrets manager.

## Prerequisites
- A OpenShift Cluster
- Ansible Navigator
- Podman

## For Deployment in OpneShift Dev Spaces
* [Deploy and configure External Secrets Manager on OpenShift Dev Spaces](docs/devspaces.md)

## Usage

**Git Clone Repo**
```
git clone https://github.com/tosin2013/external-secrets-manager.git

cd $HOME/external-secrets-manager/
```

**Configure SSH**
```
IP_ADDRESS=$(hostname -I | awk '{print $1}')
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
ssh-copy-id $USER@${IP_ADDRESS}
```

**Configure ansible vault secret**
```
curl -OL https://gist.githubusercontent.com/tosin2013/022841d90216df8617244ab6d6aceaf8/raw/92400b9e459351d204feb67b985c08df6477d7fa/ansible_vault_setup.sh
chmod +x ansible_vault_setup.sh
./ansible_vault_setup.sh
```

**Create Ansible navigator config file**
```
# export INVENTORY=bastion
# cp -avi inventories/controller/ inventories/${INVENTORY}
# cat >~/.ansible-navigator.yml<<EOF
---
ansible-navigator:
  ansible:
    inventory:
      entries:
      - $HOME/external-secrets-manager/inventories/${INVENTORY}
      - $HOME/external-secrets-manager/vars
  execution-environment:
    container-engine: podman
    enabled: true
    environment-variables:
      pass:
      - USER
    image: quay.io/takinosh/external-secrets-manager:v1.0.0
    pull:
      policy: missing
  logging:
    append: true
    file: /tmp/navigator/ansible-navigator.log
    level: debug
  playbook-artifact:
    enable: false
EOF
```

**Update inventory file**
```
vim inventories/bastion/group_vars/all.yml
```

**Deploy and configure vault**
```
$ ansible-navigator run install-vault.yaml  --extra-vars "install_vault=true" \
 --vault-password-file $HOME/.vault_password -m stdout 
```

**Copy template from /vars folder**
*For AWS Secrets*
```
$ cp vars/values-secret.aws.yaml.template vars/values-secret.yaml
```
*For Git Credentials*
```
$ cp vars/values-secret.git.yaml.template  vars/values-secret.yaml
```
*For Quay Secret*
```
$ cp vars/values-secret.quay.yaml.template  vars/values-secret.yaml
```

**Push secrets and configure secrets**
```
$ ansible-navigator run push-secrets.yaml --extra-vars "vault_push_secrets=true"   --extra-vars "vault_secrets_init=true" \
 --vault-password-file $HOME/.vault_password -m stdout 
```

**Delete and remove vault and external-secrets**
```
$ ansible-navigator run install-vault.yaml  --extra-vars "install_vault=false" \
 --vault-password-file $HOME/.vault_password -m stdout 
```

## For Developers
[Developers Guide](docs/developers.md)

## References
- [External Secrets](https://external-secrets.io/latest/)
- [Vault](https://www.vaultproject.io/)
- [Industrial Edge](https://github.com/validatedpatterns/industrial-edge)
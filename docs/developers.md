
Developers Guide
=============

## Prerequisites
* [Ansible Navigator](https://ansible.readthedocs.io/projects/navigator/)
* [Ansible Builder](https://ansible-builder.readthedocs.io/en/latest/)
* [OpenShift Cluster](https://www.openshift.com/try)

## Getting Started

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
  execution-environment:
    container-engine: podman
    enabled: true
    environment-variables:
      pass:
      - USER
    image:  localhost/external-secrets-manager:0.1.0
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


**Add hosts file**
```
# control_user=lab-user
# control_host=$(hostname -I | awk '{print $1}')
echo "[control]" > inventories/${INVENTORY}/hosts
echo "control ansible_host=${control_host} ansible_user=${control_user}" >> inventories/${INVENTORY}/hosts
```

**Create Requirement file for ansible builder** 
```
cat >ansible-builder/requirements.yml<<EOF
---
collections:
  - ansible.posix
  - containers.podman
  - community.general
  - kubernetes.core
  - community.kubernetes
EOF
```


**Build the image:**
```bash
make build-image
```

**Configure Ansible Vault**
```bash
curl -OL https://gist.githubusercontent.com/tosin2013/022841d90216df8617244ab6d6aceaf8/raw/92400b9e459351d204feb67b985c08df6477d7fa/ansible_vault_setup.sh
chmod +x ansible_vault_setup.sh
./ansible_vault_setup.sh
```

**List inventory**
```
ansible-navigator inventory --list -m stdout --vault-password-file $HOME/.vault_password
```

**Deploy and configure vault**
```
$ ansible-navigator run install-vault.yaml  --extra-vars "install_vault=true" \
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
$ ansible-navigator run install-vault.yaml  --extra-vars "install_vault=false" \
 --vault-password-file $HOME/.vault_password -m stdout 
```


When developing a new collection, you can use the following command to build the collection and install it in the execution environment:
```
make build-image
```

When you are done developing, you can remove the images and bad builds with the following commands:
```
make remove-bad-builds && make remove-images
```
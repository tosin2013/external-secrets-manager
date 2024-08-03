# Creating Vault Secrets

This document explains how to populate the `vars/values-secret.yaml` file and use the `ansible-playbook` command to push secrets to Vault, both from the command line and within Tekton pipelines.

## Populating `vars/values-secret.yaml`

To populate the `vars/values-secret.yaml` file, follow these steps:

1. Open `vars/values-secret.yaml` in your preferred text editor.
2. Add the necessary secrets in the required format. Refer to the template or schema for guidance on the structure.
3. Save the file.

## Using `ansible-playbook` from the Command Line

To push secrets to Vault using the command line, execute the following command:

```sh
ansible-playbook -i /workspace/shared-workspace/inventories/bastion/hosts /workspace/shared-workspace/push-secrets.yaml
```

Ensure that the inventory file and playbook path are correct and accessible.

## Using Tekton Pipelines

To integrate this process within Tekton pipelines, you can create a Task or PipelineRun that includes the `ansible-playbook` command. Here is an example of a Tekton Task:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: push-vault-secrets
spec:
  steps:
    - name: push-secrets
      image: ansible/ansible-runner:latest
      command: ["ansible-playbook"]
      args:
        - "-i"
        - "/workspace/shared-workspace/inventories/bastion/hosts"
        - "/workspace/shared-workspace/push-secrets.yaml"
```

You can then create a PipelineRun or TaskRun to execute this Task.

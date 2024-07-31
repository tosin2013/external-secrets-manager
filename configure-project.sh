#!/bin/bash 

oc new-project hashicorp-vault
# Create ClusterRole for patching mutatingwebhookconfigurations
cat >patch-mutatingwebhookconfiguration-clusterrole.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: patch-mutatingwebhookconfiguration-role
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: ["patch"]
EOF
oc apply -f patch-mutatingwebhookconfiguration-clusterrole.yaml
rm patch-mutatingwebhookconfiguration-clusterrole.yaml

# Create ClusterRoleBinding for the patch ClusterRole
cat >patch-mutatingwebhookconfiguration-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: patch-mutatingwebhookconfiguration-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: hashicorp-vault
roleRef:
  kind: ClusterRole
  name: patch-mutatingwebhookconfiguration-role
  apiGroup: rbac.authorization.k8s.io
EOF
oc apply -f patch-mutatingwebhookconfiguration-clusterrolebinding.yaml 
rm patch-mutatingwebhookconfiguration-clusterrolebinding.yaml
# Create ClusterRole for creating cluster-wide resources
cat >create-cluster-resources-role.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: create-cluster-resources-role
rules:
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings"]
  verbs: ["create"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: ["create"]
EOF
oc apply -f create-cluster-resources-role.yaml
rm create-cluster-resources-role.yaml
# Create ClusterRoleBinding for the create ClusterRole
cat >create-cluster-resources-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: create-cluster-resources-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: hashicorp-vault
roleRef:
  kind: ClusterRole
  name: create-cluster-resources-role
  apiGroup: rbac.authorization.k8s.io
EOF
oc apply -f create-cluster-resources-clusterrolebinding.yaml
rm create-cluster-resources-clusterrolebinding.yaml

oc apply -f tekton/deploy-vault-instance.yaml
oc apply -f tekton/tekton-shared-workspace-pvc.yaml
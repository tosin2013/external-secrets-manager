#!/bin/bash

ACTION=$1
NAMESPACE="hashicorp-vault"

if [ "$ACTION" == "create" ]; then
    oc new-project $NAMESPACE

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
  namespace: $NAMESPACE
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
- apiGroups: ["authentication.k8s.io"]
  resources: ["tokenreviews"]
  verbs: ["create"]
- apiGroups: ["authorization.k8s.io"]
  resources: ["subjectaccessreviews"]
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
  namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: create-cluster-resources-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f create-cluster-resources-clusterrolebinding.yaml
    rm create-cluster-resources-clusterrolebinding.yaml

    # Create ClusterRole for managing namespaces
    cat >namespace-manager-clusterrole.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-manager
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "create", "list", "watch", "delete"]
EOF
    oc apply -f namespace-manager-clusterrole.yaml
    rm namespace-manager-clusterrole.yaml

    # Create ClusterRoleBinding for the namespace manager ClusterRole
    cat >namespace-manager-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: namespace-manager-binding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: namespace-manager
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f namespace-manager-clusterrolebinding.yaml
    rm namespace-manager-clusterrolebinding.yaml

    # Apply Tekton resources
    oc apply -f tekton/deploy-vault-instance.yaml
    oc apply -f tekton/tekton-shared-workspace-pvc.yaml

elif [ "$ACTION" == "delete" ]; then
    oc delete project $NAMESPACE
    oc delete clusterrole patch-mutatingwebhookconfiguration-role
    oc delete clusterrolebinding patch-mutatingwebhookconfiguration-rolebinding
    oc delete clusterrole create-cluster-resources-role
    oc delete clusterrolebinding create-cluster-resources-clusterrolebinding
    oc delete clusterrole namespace-manager
    oc delete clusterrolebinding namespace-manager-binding
else
    echo "Usage: $0 [create|delete]"
    exit 1
fi

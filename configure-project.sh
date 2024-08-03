#!/bin/bash

ACTION=$1
NAMESPACE1="hashicorp-vault"
NAMESPACE2="golang-external-secrets"
OPERATOR_NAMESPACE="openshift-operators"

if [ "$ACTION" == "create" ]; then
    oc new-project $NAMESPACE1
    oc new-project $NAMESPACE2

    # Namespace 1: hashicorp-vault

    # Create ClusterRole for patching mutatingwebhookconfigurations in NAMESPACE1
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

    # Create ClusterRoleBinding for the patch ClusterRole in NAMESPACE1
    cat >patch-mutatingwebhookconfiguration-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: patch-mutatingwebhookconfiguration-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: patch-mutatingwebhookconfiguration-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f patch-mutatingwebhookconfiguration-clusterrolebinding.yaml
    rm patch-mutatingwebhookconfiguration-clusterrolebinding.yaml

    # Create ClusterRole for creating cluster-wide resources in NAMESPACE1
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

    # Create ClusterRoleBinding for the create ClusterRole in NAMESPACE1
    cat >create-cluster-resources-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: create-cluster-resources-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: create-cluster-resources-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f create-cluster-resources-clusterrolebinding.yaml
    rm create-cluster-resources-clusterrolebinding.yaml

    # Grant permissions to access and patch namespaces in NAMESPACE2
    cat >namespace-access-role.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-access-role
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list", "watch", "patch"]
EOF
    oc apply -f namespace-access-role.yaml
    rm namespace-access-role.yaml

    # Bind the namespace access role to the pipeline service account in NAMESPACE1
    cat >namespace-access-rolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: namespace-access-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: namespace-access-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f namespace-access-rolebinding.yaml
    rm namespace-access-rolebinding.yaml

    # Apply Tekton resources in NAMESPACE1
    oc apply -f tekton/deploy-vault-instance.yaml -n $NAMESPACE1
    oc apply -f tekton/tekton-shared-workspace-pvc.yaml -n $NAMESPACE1
    sleep 15
    oc create -f tekton/deploy-vault-instance-piplinerun-testme.yaml -n $NAMESPACE1

    # Grant necessary permissions to the pipeline service account for the external-secrets-operator subscription in the openshift-operators namespace
    cat >external-secrets-operator-permissions.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets-operator-permissions
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f external-secrets-operator-permissions.yaml
    rm external-secrets-operator-permissions.yaml

    # Grant patch permissions to the pipeline service account for the subscriptions resource in the openshift-operators namespace
    cat >patch-subscriptions-role.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: patch-subscriptions-role
rules:
- apiGroups: ["operators.coreos.com"]
  resources: ["subscriptions"]
  verbs: ["patch"]
EOF
    oc apply -f patch-subscriptions-role.yaml
    rm patch-subscriptions-role.yaml

    cat >patch-subscriptions-rolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: patch-subscriptions-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: patch-subscriptions-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f patch-subscriptions-rolebinding.yaml
    rm patch-subscriptions-rolebinding.yaml

elif [ "$ACTION" == "delete" ]; then
    oc delete project $NAMESPACE1
    oc delete project $NAMESPACE2
    oc delete clusterrole patch-mutatingwebhookconfiguration-role
    oc delete clusterrolebinding patch-mutatingwebhookconfiguration-rolebinding
    oc delete clusterrole create-cluster-resources-role
    oc delete clusterrolebinding create-cluster-resources-clusterrolebinding
    oc delete clusterrole namespace-access-role
    oc delete clusterrolebinding namespace-access-rolebinding
    oc delete clusterrolebinding external-secrets-operator-permissions
    oc delete clusterrole patch-subscriptions-role
    oc delete clusterrolebinding patch-subscriptions-rolebinding
else
    echo "Usage: $0 [create|delete]"
    exit 1
fi

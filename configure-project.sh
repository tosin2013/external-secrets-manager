#!/bin/bash

ACTION=$1
NAMESPACE1="hashicorp-vault"
NAMESPACE2="golang-external-secrets"

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

    # Namespace 2: golang-external-secrets

    # Create ClusterRole for managing resources in NAMESPACE2
    cat >namespace-manager-clusterrole.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-manager
rules:
- apiGroups: [""]
  resources: ["namespaces", "serviceaccounts", "secrets", "endpoints", "events", "configmaps", "services"]
  verbs: ["get", "create", "list", "watch", "delete", "patch", "update"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings"]
  verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["validatingwebhookconfigurations"]
  verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
EOF
    oc apply -f namespace-manager-clusterrole.yaml
    rm namespace-manager-clusterrole.yaml

    # Create ClusterRoleBinding for the namespace manager ClusterRole in NAMESPACE2
    cat >namespace-manager-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: namespace-manager-binding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: namespace-manager
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f namespace-manager-clusterrolebinding.yaml
    rm namespace-manager-clusterrolebinding.yaml

    # Create ClusterRole for external-secrets in NAMESPACE2
    cat >external-secrets-clusterrole.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets-role
rules:
- apiGroups: [""]
  resources: ["namespaces", "serviceaccounts", "secrets", "endpoints", "events", "configmaps", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["validatingwebhookconfigurations"]
  verbs: ["get", "list", "watch", "update", "patch", "create"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "create", "update", "patch"]
- apiGroups: ["external-secrets.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete", "deletecollection"]
- apiGroups: ["generators.external-secrets.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete", "deletecollection"]
EOF
    oc apply -f external-secrets-clusterrole.yaml
    rm external-secrets-clusterrole.yaml

    # Create ClusterRoleBinding for external-secrets ClusterRole in NAMESPACE2
    cat >external-secrets-clusterrolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets-binding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: external-secrets-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f external-secrets-clusterrolebinding.yaml
    rm external-secrets-clusterrolebinding.yaml

    # Create custom SecurityContextConstraints for NAMESPACE2
    cat >custom-scc.yaml<<EOF
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: custom-scc
allowPrivilegedContainer: false
allowHostNetwork: false
allowHostPorts: false
allowHostPID: false
allowHostIPC: false
allowHostDirVolumePlugin: false
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SETUID
- SETGID
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
- nfs
- hostPath
runAsUser:
  type: MustRunAsRange
  uidRangeMin: 1001370000
  uidRangeMax: 1001379999
seLinuxContext:
  type: MustRunAs
fsGroup:
  type: MustRunAs
  ranges:
  - min: 1001370000
    max: 1001379999
supplementalGroups:
  type: MustRunAs
  ranges:
  - min: 1001370000
    max: 1001379999
EOF
    oc apply -f custom-scc.yaml
    rm custom-scc.yaml

    # Assign the custom SCC to the pipeline service account in NAMESPACE2
    oc adm policy add-scc-to-user custom-scc -z pipeline -n $NAMESPACE2

    # Additional Role for serviceaccounts/token creation in NAMESPACE2
    cat >serviceaccount-token-creator-role.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: serviceaccount-token-creator-role
rules:
- apiGroups: [""]
  resources: ["serviceaccounts/token"]
  verbs: ["create"]
EOF
    oc apply -f serviceaccount-token-creator-role.yaml
    rm serviceaccount-token-creator-role.yaml

    # Bind the role to the pipeline service account in NAMESPACE2
    cat >serviceaccount-token-creator-rolebinding.yaml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: serviceaccount-token-creator-rolebinding
subjects:
- kind: ServiceAccount
  name: pipeline
  namespace: $NAMESPACE1
roleRef:
  kind: ClusterRole
  name: serviceaccount-token-creator-role
  apiGroup: rbac.authorization.k8s.io
EOF
    oc apply -f serviceaccount-token-creator-rolebinding.yaml
    rm serviceaccount-token-creator-rolebinding.yaml

elif [ "$ACTION" == "delete" ]; then
    oc delete project $NAMESPACE1
    oc delete project $NAMESPACE2
    oc delete clusterrole patch-mutatingwebhookconfiguration-role
    oc delete clusterrolebinding patch-mutatingwebhookconfiguration-rolebinding
    oc delete clusterrole create-cluster-resources-role
    oc delete clusterrolebinding create-cluster-resources-clusterrolebinding
    oc delete clusterrole namespace-access-role
    oc delete clusterrolebinding namespace-access-rolebinding
    oc delete clusterrole namespace-manager
    oc delete clusterrolebinding namespace-manager-binding
    oc delete clusterrole external-secrets-role
    oc delete clusterrolebinding external-secrets-binding
    oc delete scc custom-scc
    oc delete clusterrole serviceaccount-token-creator-role
    oc delete clusterrolebinding serviceaccount-token-creator-rolebinding
else
    echo "Usage: $0 [create|delete]"
    exit 1
fi

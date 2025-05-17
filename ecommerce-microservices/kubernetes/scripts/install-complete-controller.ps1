# PowerShell script for complete AWS Load Balancer Controller installation with webhook support
# This approach uses AWS's official Helm chart content

# Extract cluster name from current context
$CONTEXT = kubectl config current-context
if ($CONTEXT -match "cluster/(.*?)($|\s)") {
    $CLUSTER_NAME = $Matches[1]
} else {
    $CLUSTER_NAME = "ecommerce-eks-cluster"  # Default based on your previous output
}

Write-Host "Installing complete AWS Load Balancer Controller for cluster: $CLUSTER_NAME" -ForegroundColor Cyan

# Get AWS Account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Green

# Clean up any existing controller installation
Write-Host "Cleaning up any existing controller installation..." -ForegroundColor Yellow
kubectl delete deployment -n kube-system aws-load-balancer-controller 2>$null
kubectl delete serviceaccount -n kube-system aws-load-balancer-controller 2>$null
kubectl delete clusterrole aws-load-balancer-controller 2>$null
kubectl delete clusterrolebinding aws-load-balancer-controller 2>$null

# Install cert-manager (required for webhook)
Write-Host "Installing cert-manager (required for webhook validation)..." -ForegroundColor Yellow
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml

Write-Host "Waiting for cert-manager to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Create IAM policy JSON directly
$IAM_POLICY = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
"@

Set-Content -Path "iam-policy.json" -Value $IAM_POLICY

# Check if policy already exists
$POLICY_ARN = aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text

if (-not $POLICY_ARN) {
    Write-Host "Creating IAM policy..." -ForegroundColor Yellow
    $POLICY_ARN = aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json --query "Policy.Arn" --output text
} else {
    Write-Host "Using existing IAM policy: $POLICY_ARN" -ForegroundColor Green
}

# Create a service account and role
Write-Host "Creating Kubernetes service account..." -ForegroundColor Yellow

$SA_YAML = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: $POLICY_ARN
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
rules:
  - apiGroups:
      - ""
      - extensions
    resources:
      - configmaps
      - endpoints
      - events
      - ingresses
      - ingresses/status
      - services
    verbs:
      - create
      - get
      - list
      - update
      - watch
      - patch
  - apiGroups:
      - ""
      - extensions
    resources:
      - nodes
      - pods
      - secrets
      - services
      - namespaces
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - networking.k8s.io
    resources:
      - ingresses
      - ingresses/status
      - ingressclasses
    verbs:
      - get
      - list
      - watch
      - update
      - create
      - patch
  - apiGroups:
      - networking.k8s.io
    resources:
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - discovery.k8s.io
    resources:
      - endpointslices
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - list
      - watch
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      - aws-load-balancer-controller-leader
    verbs:
      - get
      - update
      - patch
  - apiGroups:
      - discovery.k8s.io
    resources:
      - endpointslices
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - cert-manager.io
    resources:
      - certificates
      - certificaterequests
      - issuers
    verbs:
      - get
      - list
      - watch
      - update
      - create
      - patch
  - apiGroups:
      - admissionregistration.k8s.io
    resources:
      - validatingwebhookconfigurations
    verbs:
      - get
      - list
      - watch
      - update
      - create
      - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-load-balancer-controller
subjects:
  - kind: ServiceAccount
    name: aws-load-balancer-controller
    namespace: kube-system
"@

Set-Content -Path "alb-controller-rbac.yaml" -Value $SA_YAML
kubectl apply -f alb-controller-rbac.yaml

# Create the controller deployment with webhook support
$CONTROLLER_YAML = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: controller
      app.kubernetes.io/name: aws-load-balancer-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/name: aws-load-balancer-controller
    spec:
      containers:
        - name: controller
          image: amazon/aws-alb-ingress-controller:v2.4.5
          args:
            - --cluster-name=$CLUSTER_NAME
            - --ingress-class=alb
            - --aws-vpc-id=vpc-xxxxxxxxxxxxxxxxx
            - --aws-region=us-west-2
          ports:
            - name: webhook-server
              containerPort: 9443
              protocol: TCP
          resources:
            limits:
              cpu: 200m
              memory: 500Mi
            requests:
              cpu: 100m
              memory: 200Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
      serviceAccountName: aws-load-balancer-controller
      terminationGracePeriodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: aws-load-balancer-webhook-service
  namespace: kube-system
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
spec:
  ports:
    - port: 443
      targetPort: 9443
      protocol: TCP
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
"@

Set-Content -Path "alb-controller-deployment.yaml" -Value $CONTROLLER_YAML
kubectl apply -f alb-controller-deployment.yaml

# Create a ValidatingWebhookConfiguration with proper CA bundle
$WEBHOOK_YAML = @"
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: aws-load-balancer-webhook
  annotations:
    cert-manager.io/inject-ca-from: kube-system/aws-load-balancer-serving-cert
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
webhooks:
  - name: validate.ingress.alb.k8s.aws
    matchPolicy: Equivalent
    rules:
      - apiGroups:
          - extensions
          - networking.k8s.io
        apiVersions:
          - v1beta1
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - ingresses
    failurePolicy: Fail
    sideEffects: None
    clientConfig:
      service:
        name: aws-load-balancer-webhook-service
        namespace: kube-system
        path: /validate-networking-v1-ingress
    admissionReviewVersions:
      - v1beta1
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: aws-load-balancer-serving-cert
  namespace: kube-system
spec:
  dnsNames:
    - aws-load-balancer-webhook-service.kube-system.svc
    - aws-load-balancer-webhook-service.kube-system.svc.cluster.local
  issuerRef:
    kind: Issuer
    name: aws-load-balancer-selfsigned-issuer
  secretName: aws-load-balancer-tls
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: aws-load-balancer-selfsigned-issuer
  namespace: kube-system
spec:
  selfSigned: {}
"@

Set-Content -Path "alb-webhook.yaml" -Value $WEBHOOK_YAML
kubectl apply -f alb-webhook.yaml

Write-Host "Waiting for controller and webhook to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

Write-Host "`nChecking controller status:" -ForegroundColor Cyan
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nChecking webhook service:" -ForegroundColor Cyan
kubectl get svc -n kube-system aws-load-balancer-webhook-service

Write-Host "`nAWS Load Balancer Controller installation with webhook completed!" -ForegroundColor Green
Write-Host "You can update and apply your AWS ALB Ingress resources:" -ForegroundColor Cyan
Write-Host "kubectl apply -f aws-alb-ingress.yaml" -ForegroundColor White

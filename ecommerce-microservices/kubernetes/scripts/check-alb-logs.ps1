# PowerShell script to diagnose AWS Load Balancer Controller CrashLoopBackOff

Write-Host "Getting controller pod logs..." -ForegroundColor Yellow
$POD_NAME = kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o jsonpath="{.items[0].metadata.name}"
kubectl logs -n kube-system $POD_NAME

Write-Host "`nChecking pod details for more information..." -ForegroundColor Yellow
kubectl describe pod -n kube-system $POD_NAME

# Another common issue is missing VPC ID - let's prepare a fix for that
Write-Host "`nGetting VPC information from AWS..." -ForegroundColor Cyan
$VPC_ID = aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*ecommerce*" --query "Vpcs[0].VpcId" --output text
if (-not $VPC_ID) {
    Write-Host "No VPC with 'ecommerce' tag found, listing all VPCs:" -ForegroundColor Yellow
    aws ec2 describe-vpcs --query "Vpcs[*].[VpcId,Tags[?Key=='Name'].Value|[0]]" --output text
    Write-Host "`nPlease enter the correct VPC ID from the list above:" -ForegroundColor Cyan
    $VPC_ID = Read-Host -Prompt "VPC ID"
}

Write-Host "`nUsing VPC ID: $VPC_ID" -ForegroundColor Green
Write-Host "Creating fixed controller deployment..." -ForegroundColor Yellow

# Create fixed deployment YAML
$FIXED_CONTROLLER = @"
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
          image: amazon/aws-alb-ingress-controller:v2.4.4
          args:
            - --cluster-name=ecommerce-eks-cluster
            - --ingress-class=alb
            - --aws-vpc-id=$VPC_ID
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
"@

Set-Content -Path "fixed-controller.yaml" -Value $FIXED_CONTROLLER

Write-Host "`nApplying fixed controller deployment..." -ForegroundColor Yellow
kubectl apply -f fixed-controller.yaml

Write-Host "`nWaiting for controller to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`nChecking controller status again:" -ForegroundColor Cyan
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nIf the controller is still failing, consider temporarily disabling the webhook:" -ForegroundColor Yellow
Write-Host "kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook" -ForegroundColor White

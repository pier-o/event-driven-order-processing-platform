$ErrorActionPreference = "Stop"

# --------------------------------------------------
# Configuration
# --------------------------------------------------

$AwsRegion = $env:TF_BACKEND_REGION
$ImageTag  = $env:TF_VAR_image_tag

if (-not $AwsRegion) {
    Write-Error "TF_BACKEND_REGION environment variable is not set."
    exit 1
}

if (-not $ImageTag) {
    Write-Error "TF_VAR_image_tag environment variable is not set."
    exit 1
}

# --------------------------------------------------
# Get ECR repositories from Terraform
# --------------------------------------------------

$AuthRepo = terraform -chdir=terraform/live/global/ecr output -raw auth_repository_url
$OrderRepo = terraform -chdir=terraform/live/global/ecr output -raw orders_repository_url
$NotifyRepo = terraform -chdir=terraform/live/global/ecr output -raw notifications_repository_url

if (-not $AuthRepo -or -not $OrderRepo -or -not $NotifyRepo) {
    Write-Error "Could not get ECR repository URLs from Terraform."
    exit 1
}

# --------------------------------------------------
# AWS / ECR information
# --------------------------------------------------

$AccountId = aws sts get-caller-identity --query Account --output text

if (-not $AccountId) {
    Write-Error "Could not get AWS account ID."
    exit 1
}

$Registry = "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com"

# --------------------------------------------------
# Build application images
# --------------------------------------------------

Write-Host ""
Write-Host "Building Docker images..." -ForegroundColor Cyan

docker build -t "order-platform-auth:$ImageTag" ./app/auth
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build auth image."
    exit 1
}

docker build -t "order-platform-order:$ImageTag" ./app/order
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build order image."
    exit 1
}

docker build -t "order-platform-notify:$ImageTag" ./app/notify
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build notify image."
    exit 1
}

# --------------------------------------------------
# Login to ECR
# --------------------------------------------------

Write-Host ""
Write-Host "Logging in to ECR..." -ForegroundColor Cyan

cmd /c "aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $Registry"

if ($LASTEXITCODE -ne 0) {
    Write-Error "ECR login failed."
    exit 1
}

# --------------------------------------------------
# Create temporary ECR tags
# --------------------------------------------------

$AuthEcrImage = "$AuthRepo`:$ImageTag"
$OrderEcrImage = "$OrderRepo`:$ImageTag"
$NotifyEcrImage = "$NotifyRepo`:$ImageTag"

Write-Host ""
Write-Host "Tagging images for ECR..." -ForegroundColor Cyan

docker tag "order-platform-auth:$ImageTag" $AuthEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to tag auth image."
    exit 1
}

docker tag "order-platform-order:$ImageTag" $OrderEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to tag order image."
    exit 1
}

docker tag "order-platform-notify:$ImageTag" $NotifyEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to tag notify image."
    exit 1
}

# --------------------------------------------------
# Push images
# --------------------------------------------------

Write-Host ""
Write-Host "Pushing images to ECR..." -ForegroundColor Cyan

$PushFailed = $false

docker push $AuthEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Auth image push failed." -ForegroundColor Red
    $PushFailed = $true
}

docker push $OrderEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Order image push failed." -ForegroundColor Red
    $PushFailed = $true
}

docker push $NotifyEcrImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Notify image push failed." -ForegroundColor Red
    $PushFailed = $true
}

# --------------------------------------------------
# Cleanup temporary ECR tags
# --------------------------------------------------

if ($PushFailed) {
    Write-Host ""
    Write-Host "One or more images failed to push." -ForegroundColor Red
    Write-Host "Temporary ECR tags were NOT removed so you can inspect/retry them."
    exit 1
}

Write-Host ""
Write-Host "All images pushed successfully." -ForegroundColor Green
Write-Host "Removing temporary ECR tags..." -ForegroundColor Cyan

docker rmi $AuthEcrImage
docker rmi $OrderEcrImage
docker rmi $NotifyEcrImage

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "Local images kept:"
Write-Host "  order-platform-auth:$ImageTag"
Write-Host "  order-platform-order:$ImageTag"
Write-Host "  order-platform-notify:$ImageTag"

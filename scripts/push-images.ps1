param (
    [Parameter(Mandatory = $true)]
    [string]$ImageTag
)

$AuthRepo = terraform -chdir=terraform/live/global/ecr output -raw auth_repository_url
$OrderRepo = terraform -chdir=terraform/live/global/ecr output -raw orders_repository_url
$NotifyRepo = terraform -chdir=terraform/live/global/ecr output -raw notifications_repository_url

$AwsRegion = "eu-west-1"

$AccountId = aws sts get-caller-identity --query Account --output text

$Registry = "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com"

cmd /c "aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $Registry"

docker tag "order-platform-auth:$ImageTag" "$AuthRepo`:$ImageTag"
docker tag "order-platform-order:$ImageTag" "$OrderRepo`:$ImageTag"
docker tag "order-platform-notify:$ImageTag" "$NotifyRepo`:$ImageTag"

docker push "$AuthRepo`:$ImageTag"
docker push "$OrderRepo`:$ImageTag"
docker push "$NotifyRepo`:$ImageTag"
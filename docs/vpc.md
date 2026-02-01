# Setup VPC

## Enable RAM sharing with AWS Organization

```
aws ram enable-sharing-with-aws-organization --profile admin
```

## Create VPC

```
powershell -ExecutionPolicy Bypass -File bin\deploy_vpc.ps1
```

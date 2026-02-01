# AWS setup

## Initial setup

From AWS Management Console:

- login with Google
- AWS account creation
- MFA setup for root user
- enable AWS Organizations with ALL features
- enable IAM Identity Center (SSO)

### Verification

```
aws organizations describe-organization

aws sso-admin list-instances
```

## User Setup

### Admin Role Setup

```sh
IDSTORE_ID=`aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text`

aws identitystore create-user \
    --identity-store-id $IDSTORE_ID \
    --user-name "admin-user" \
    --display-name "Organization Admin" \
    --name '{"FamilyName": "Admin", "GivenName": "Org"}'

USER_ID=`aws identitystore list-users --identity-store-id $IDSTORE_ID --query "Users[0].UserId" --output text`

IDINSTANCE_ARN=`aws sso-admin list-instances --query "Instances[0].InstanceArn" --output text`

aws sso-admin create-permission-set --instance-arn $IDINSTANCE_ARN --name AdministratorAccess

PS_ARN=`aws sso-admin list-permission-sets --instance-arn $IDINSTANCE_ARN --query "PermissionSets[0]" --output text`

aws sso-admin attach-managed-policy-to-permission-set \
    --instance-arn $IDINSTANCE_ARN \
    --permission-set-arn $PS_ARN \
    --managed-policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`

aws sso-admin create-account-assignment \
    --instance-arn $IDINSTANCE_ARN \
    --target-id $ACCOUNT_ID \
    --target-type "AWS_ACCOUNT" \
    --permission-set-arn $PS_ARN \
    --principal-type "USER" \
    --principal-id $USER_ID

aws sso-admin list-account-assignment-creation-status  --instance-arn $IDINSTANCE_ARN
```

Note: Reset password from IAM Identity Center Console

### AWS CLI Login

```
aws configure sso

aws sts get-caller-identity --profile admin
```

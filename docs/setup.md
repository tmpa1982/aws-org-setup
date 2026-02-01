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

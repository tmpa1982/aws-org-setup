# Setup VPC

## SSO for CLI

```
aws configure sso

SSO session name (Recommended): tmpa-shared
SSO start URL [None]: https://d-9667a4e83f.awsapps.com/start
SSO region [None]: ap-southeast-1
SSO registration scopes [sso:account:access]:
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-southeast-1.amazonaws.com/authorize?response_type=code&client_id=LaIjX9jUF8jaXb8fvziq0WFwLXNvdXRoZWFzdC0x&redirect_uri=http%3A%2F%2F127.0.0.1%3A61851%2Foauth%2Fcallback&state=9aafb583-8117-46de-a3c1-b9916b1a1997&code_challenge_method=S256&scopes=sso%3Aaccount%3Aaccess&code_challenge=WdKYgKVgs7jZ3FMujj1n20CMfttFzmkSgbwUc2X0M6o
There are 3 AWS accounts available to you.
Using the account ID 558460665868
The only role available to you is: AdministratorAccess
Using the role name "AdministratorAccess"
Default client Region [None]: ap-southeast-1
CLI default output format (json if not specified) [None]: yaml-stream
Profile name [AdministratorAccess-558460665868]: shared
```

## Login to AWS Console

https://d-9667a4e83f.awsapps.com/start

## Enable RAM sharing with AWS Organization

```
aws ram enable-sharing-with-aws-organization --profile admin
```

## Create VPC

```
powershell -ExecutionPolicy Bypass -File bin\deploy_vpc.ps1
```

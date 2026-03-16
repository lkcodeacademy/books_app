# Team Project
## Books App
### Create a deployment pipeline for a web application.


```bash
Requirements
Create a CI/CD pipeline to create infra using terraform
Create a CI/CD pipeline to build and push the Docker image to Docker Hub
Create a CI/CD pipeline to configure a VM using ansible
Create a CI/CD pipeline to deploy the application using ansible
```

## GitHub Actions OIDC

To avoid storing long‑lived AWS credentials in the repository, the
`create-infrastructure` workflow now uses GitHub's OpenID Connect (OIDC)
provider and assumes an IAM role.

1. Create an IAM role in AWS with a trust policy for the GitHub
   OIDC provider and restrict it to the `repo:<owner>/<repo>:ref:refs/heads/main`
   (or other branches) as needed.
2. Grant the role appropriate permissions for Terraform operations.
3. In the repository settings, add a secret named `AWS_ROLE_ARN` with
   the role's ARN.
4. Trigger the workflow via `workflow_dispatch` or push to `main`.

The workflow will automatically obtain temporary credentials from AWS
by exchanging the GitHub‑issued token via OIDC. No AWS access keys are
required as inputs.

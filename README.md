## 🏗️ My AWS Infrastructure Foundation

This is my core infrastructure-as-code repository. I built this to establish a secure, scalable AWS environment that handles everything from identity management and auditing to cost control. It uses a "Bootstrap" pattern to ensure that the CI/CD pipeline itself is managed and secured by Terraform.

## 📂 Project Organization

I’ve structured this project into Root Modules to ensure that changes to one area don't accidentally break another. Each folder maintains its own independent state file.

`/bootstrap`: My starting point. This sets up the S3 backend for state, DynamoDB for locking, and the IAM Roles that GitHub Actions uses to deploy the rest of the stack.

`/environments/common`: The "shared services" layer. This is where I deploy my security modules, CloudTrail auditing, and AWS Budgets.

`/modules`: My library of reusable logic. I keep these generic so they can be called by any environment folder to keep the code DRY.

## 🔐 Security & IAM Strategy
Least Privilege CI/CD

My Terraform-Deploy-Role is designed with a "Split-Scope" policy to balance security with functionality:

Account-Level Discovery: I use Resource: "*" for actions like cloudtrail:DescribeTrails. This is necessary because these specific AWS APIs do not support resource-level permissions.

Resource-Level Management: For destructive or modification actions (Update/Delete), I scope permissions to specific ARNs to ensure the role only modifies what it strictly owns.

Deterministic Naming

To solve the "Bootstrap Paradox" (where a role needs permissions for a resource that hasn't been created yet), I use Deterministic ARN Construction. By calculating the ARN string in advance using my Account ID and a fixed naming convention, I can deploy the IAM Role in bootstrap before the common infrastructure even exists.

🚀 Getting Started

**1. Manual Bootstrap**

Since there is no "role" until I create one, the first run must be performed manually from a local machine with administrative access:

Navigate to the `/bootstrap` directory.

Run:
```
terraform init
```

Run:
```
terraform apply
```

**2. Local CI/CD Testing with act**

I use [act](https://github.com/nektos/act) to test my GitHub Actions workflows locally. This saves me from having to "commit and push" just to debug a YAML error. To keep my credentials secure and my terminal history clean, I use a .secrets file.

Create a .secrets file in the root directory:
Bash

# .secrets file format
```
AWS_ACCOUNT_ID=123456789012

AWS_REGION=us-east-1
```
# Add other GitHub secrets here

Run the local simulation:
Bash

## 🔧 My Common Troubleshooting Steps

Secret Casing: I remember that while GitHub Secrets are UPPERCASE, I must map them to lower_snake_case Terraform variables in my YAML using the TF_VAR_ prefix (e.g., TF_VAR_aws_region).

IAM Discovery Errors: If I get an "Access Denied" on a Describe call, I check if I've tried to scope it to a specific resource. Most Describe calls require Resource: "*".

Cross-Folder References: If I need a value from the common folder inside the bootstrap folder, I use terraform_remote_state or an AWS Data Source to look it up, rather than trying to call a module across directories.
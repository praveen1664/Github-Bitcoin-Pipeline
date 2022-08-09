Github Actions Integration with terraform to create VPC->SG-> ECR -> ECS- > EFS & mounting of EFS
==================================================================================================
# What it contains
1. ### It contains a terraform code create ECR, ECS, Task defnitions, VPC, Security groups, EFS, policies to mount EFS.

2. ### How it could be run?
It also contain 2 Github Work Flow 
    1. "Terraform_Plan_Apply"
    2. Terraform destroy

##### 1. Workflow "Terraform_Plan_Apply" will triggred automatically with a push in main branch with Github Actions to:

 a. Triggre Terraform to create 
    A. VPC
    B. Necessary Security Groups
    C. Elastic Container Registry
    D. Elastic File Systems
    E. Necessary Tasks Definitions
    F. Task definitions
    E. Mouting Point of EFS to data
    G. Mouting of EFS to ECS tasks
    H. Necessary Policies.

##### 2. GitHub Work Flow Name Terraform Destroy Prsent in Gighub->Repo->Actions which could be triggered manually 
b. To destroy all the infrastructure created in teraform.

What You need
===============
A valid Github Repo 
A Valid AWS account with programatic access enabled with access_key & secret_key.

What You need to do to test this code?
======================================
### (A) test it in Same repo & my account.
----------------------------------------
1. Clone this repo & do some dummy update say in add some comment in READMDEmd.
2. Make some meaningful comments & do a push.
3. The Github action "Terraform_Plan_Apply" will trigger automatically.
4. You can Watch it to be completed in repo->Actions->Terraform_Plan_Apply workflow
5. check all of the logs.
6. You can contact me to see how the infra has been created in aws.
7. Run anoher work flow to destroy the infra from 
   repo -> Actions-> terraform_destroy to destroy the infra. (You need toenter Destroy to proceed further)
----------------------------------------------
### (B) Test this from command line on your system
------------------------------
1. Take a system which have terraform installed.
2. Install aws-cli
3. do aws configure from cli.
4. Clone my repository.
5. In providers section uncomment the profile block & region
6. Also remove my remote backend
7. Goto -> environment\demo folder & run following commands
  ``sh 
   a) terraform init
   b) terraform plan
   c) terraform apply
  ``sh
   To destroy Please rund the following

   d) terraform destroy
-------------------------------------------------------
### (C) Want to test it with your github account then
---------------------------------------------------
1. Clone this repo from main branch
2. Remove my backend from providers section.
3. Add your backend.
4. Create your repo & update secrets in your repo by creating 2 variables 
    a) AWS_ACCESS_KEY_ID for your user access Key
    b) AWS_SECRET_ACCESS_KEY for your secret Key.
5. In .github\workflowfolder\terraform.yml update aws-region with your region of choice.
6. Add this code to your repo.
7. Do some dummy checkin to main.
8. The Github action "Terraform_Plan_Apply" will trigger automatically.
9. You can Watch it to be completed in repo->Actions->Terraform_Plan_Apply workflow
10. Check all of the logs.
11. You can cross check your aws account to verify the build.
12. Run anoher work flow from repo -> Actions-> terraform_destroy to destroy the infra. (You need toenter Destroy to proceed further)





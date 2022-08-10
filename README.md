Github Actions Integration with terraform to create VPC,SG, ECR , ECS, EFS & mounting of EFS
==================================================================================================
# What it contains
1. ### This is a complete CI-CD pipeline through Github workflow actions present in .github folder along with Terraform code present in modules folder & environment/demo folder. It also contains the Dockerfile & other necessary source code for building & deploying Bitcoin core 0.21.0 in docker & deploying on ECs with EFS enable. It follow the below routein:
As soon as there is a checkin in main branch a github workflow will trigger the terrform scripts with workflow name tearrform_plan_apply which will create the followings on broader level with terraform:

    A. VPC
    B. CIDR
    C. Subnets
    D. Necessary Security Groups
    E. Elastic Container Registry
    F. Login to Registry
    G. Do a docker build for BitCoin 0.21.0 with 442 Security checks embedded inside the docker file. Whereas checksum itslef is also verified inside the file.
    H. Create Elastic File Systems
    I. Mount the file syste.
    J. Create Tasks Definitions
    K. Mouting Point of EFS to data
    L. Necessary Policies.
    M. Policies to assume role.

2. ### How it could be run?
##### It contain 2 Github Actions Work Flow as part of CI CD
   ###### 1. "Terraform_Plan_Apply"
   ###### 2. Terraform destroy

##### 1. Workflow "Terraform_Plan_Apply" will triggred automatically with a push in main branch with Github Actions to:

##### 2. There is another GitHub Work which is provided to destroy the infra created in first step. Terraform Destroy Prsent in Gighub,Repo,Actions which could be triggered manually. No Automation is provided here. Please run this if you have run the first GitHub action workflow. It is used to 
b. To destroy all the infrastructure created in teraform.

What You need
===============
A valid Github Repo 
A Valid AWS account with programatic access enabled with access_key & secret_key.

What You need to do to test this code?
======================================
### (A) Test it in Same repo, same github account my aws account in same structure the please contact me.
----------------------------------------
1. Clone/checkout this repo & do some dummy checkin say add some comment in READMDEmd.
2. Make some meaningful comments & do a push.
3. The Github action "Terraform_Plan_Apply" will trigger automatically.
4. You can Watch it to be completed in repo,Actions,Terraform_Plan_Apply workflow
5. check all of the logs.
6. You can contact me to see how the infra has been created in aws.
7. Run anoher work flow to destroy the infra from 
   repo , Actions, terraform_destroy to destroy the infra. (You need toenter Destroy to proceed further)
----------------------------------------------
### (B) Test this from command line on your system
------------------------------
1. Take a system which have terraform & docker installed installed.
2. Install aws-cli
3. do aws configure from cli.
4. Clone my repository.
5. In providers section uncomment the profile block & region
6. Also remove my remote backend
7. First go to modules/ecr folder & run following. It will create the ECR repo
           ``
               a) terraform init
               b) terraform plan
               c) terraform apply
            ``
8. Now come back to root folder & do a docker build with docker file. Push the Images to you ECR build earlier after setting up your aws profile.
9. Goto , environment\demo folder & run following commands
  ``sh 
   a) terraform init
   b) terraform plan
   c) terraform apply
  ``sh
   To destroy Please rund the following

   d) terraform destroy
-------------------------------------------------------
### (C) Want to test it with your github account in your aws  then use the followings
---------------------------------------------------
1. Clone this repo from main branch
2. Remove my backend from providers section.
3. Add your backend.
4. Create your repo & update secrets in your repo by creating 2 variables 
    a) AWS_ACCESS_KEY_ID for your user access Key
    b) AWS_SECRET_ACCESS_KEY for your secret Key.
    c) AWS_REGION for your favourite region.
5. In .github\workflowfolder\terraform.yml update aws-region with your region of choice.
6. Add this code to your repo.
7. Do some dummy checkin to main.
8. The Github action "Terraform_Plan_Apply" will trigger automatically.
9. You can Watch it to be completed in repo,Actions,Terraform_Plan_Apply workflow
10. Check all of the logs.
11. You can cross check your aws account to verify the build.
12. Run anoher work flow from repo , Actions, terraform_destroy to destroy the infra. (You need toenter Destroy to proceed further)





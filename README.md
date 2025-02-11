# trellis-mvp-terraform
Instructions for using Terraform to deploy Trellis resources to a Google Cloud Platform (GCP) project.

# Terraforming instructions

## Prerequisites 
Before trying to use or deploy Trellis we recommend becoming knowledgable about cloud computing, networking, and GCP as a whole. Using a cloud platform is different, and in many ways more complex, than using a local computer or a high-performance computing cluster. They offer a lot of functionality, but also fewer guardrails against generating massive computing bills.

Once you are comfortable using GCP, you will need to provision a GCP project to get started.

## A. Install Terraform
https://learn.hashicorp.com/terraform/getting-started/install.html

## B. Deploy external bastion node (optional)
The external bastion is deployed to a separate network & project from Trellis. In order to access Trellis resources such as the database and AI notebook, users will first connect to the external bastion host, then hop to the bastion host inside the Trellis project & network, and then to the Trellis resource. If you are not handling high or medium risk data, you can probably skip this and go to step C.

**From the repository root directory, navigate to the external-bastion Terraform module.**

```
cd external-bastion
```

1. **Create a tfvars file.**
The tfvars file stores variable values that will be used to deploy Trellis. All of the required variables are listed in the variables.tf file. In this case you need to provide the ID of your Google Cloud project as well as the IP of local machine you will use to connect to the bastion host. If you are at Stanford, we recommend using the IP of an SCG cluster login node, since it's IP is static. The name of the tfvars file is arbitrary, just make sure it had the extension ".tfvars". Replace the bracketed values with your own and remove the brackets. Run the command to create your tfvars file.

```
printf 'project="{your-project-name}"\nlocal-ip="{your-local-ip}"' > my.tfvars
```

2. **Initialize Terraform.**

```
terraform init
```

3. **Plan terraform.**
Run the 'terraform plan' operation and fix any issues that are identified.

```
terraform plan --var-file=my.tfvars
```

4. **Apply terraforming.**

```
terraform apply --var-file=my.tfvars
```

5. (optional) Use the `destroy` command if you want to destroy terraformed resources.

```
terraform destroy --var-file=my.tfvars
```

6. **Navigate back to the root directory.**

```
cd ../
```
## C. Deploy permanent resources
Any resources deployed by Terraform can also be changed or destroyed by Terraform. There are some resources, particularly data storage ones, which should never be destroyed. To guard against destruction or prevent Terraform errors due to inability to destroy them, we deploy them separately from the main Trellis resources.

**From the root directory, navigate to the permanent resources Terraform module.**

```
cd perma-resources
```

1. **Create a tfvars file.**
Create a tfvars file and populate it with values for `project` and `region`. You must specify your project ID, but if you do not specify a region, you can see from the `variables.tf` file that it will default to `us-west1`. Replace the bracketed values with your own and remove the brackets. Run the command to create your tfvars file.

```
printf 'project="{your-project-name}"\nregion="{your-gce-region}"' > my.tfvars
```

2. **Initialize Terraform.**

```
terraform init
```

3. **Plan terraform.**
Run the 'terraform plan' operation and fix any issues that are identified.

```
terraform plan --var-file=my.tfvars
```

4. **Apply terraforming.**

```
terraform apply --var-file=my.tfvars
```

5. (optional) Use the `destroy` command if you want to destroy terraformed resources.

```
terraform destroy --var-file=my.tfvars
```

6. **Navigate back to the root directory.**

```
cd ../
```

## D. Connect GitHub repositories to Cloud Build
You will need to connect the Trellis functions repository as well as the GATK repo to Cloud Build. From the GCP web console navigate to the Cloud Build section, and select the Triggers pane. At the top, click "CONNECT REPOSITORY" and follow the instructions to connect both repos. The repository information is ddescribed in the `variables.tf` object.

## E. Create App Engine Application from web console
Go to the App Engine page and click the button to create an app. If you have already created one, you may need to change the app-engine-region variable to match yours.

## F. Terraform remaining Trellis resources
**From the root directory, navigate to the primary trellis Terraform module.**

```
cd trellis
```

1. **Create a tfvars file.**
There are only two variables which do not have default values; `project`, `external-bastion-ip`, `db-user`, and `db-passphrase`. The external bastion IP refers to the bastion node you created in step B. If you skipped that step, you'll need to comment out the `trellis-allow-bastion-bastion` firewall rule in `network.tf` & commend out this variable from `variables.tf`. If you would like to change the default values of other variables specified in `variables.tf` you can also add those key/value pairs to the tfvars file.

```
printf 'project="{your-project-name}"\nexternal-bastion-ip="{your-bastion-ip}"\ndb-user="{your-user}"\ndb-passphrase="{your-passphrase}"' > my.tfvars
```

2. **Initialize Terraform.**

```
terraform init
```

3. **Import current project state.**
```
terraform import -var-file=my.tfvars google_project.trellis_project {your-project-id}
```

3. **Plan terraform.**
Run the 'terraform plan' operation and fix any issues that are identified.

```
terraform plan --var-file=my.tfvars
```

4. **Apply terraforming.**

```
terraform apply --var-file=my.tfvars
```

5. (optional) Use the `destroy` command if you want to destroy terraformed resources. WARNING: if you imported project, this will destroy the project iself too.

```
terraform destroy --var-file=my.tfvars
```

## G. Navigate to the Cloud Build console and activate all triggers.
In order to deploy all serverless functions managed by Cloud Build triggers, you'll have to create a new git commit or manually activate the triggers.

NOTE: In the future, we plan to manage Cloud Functions directly as Terraform resources.

## H. Login to database via web browser & update username & password.
You can access the Neo4j GUI interface by navigating to the IP of your database instance and accessing port 7474 (https://your-neo4j-ip:7474). The default credentials for neo4j are "neo4j" and "password", and you should be prompted to change them upon login.

## I. Add database indexes.
Database indexes are used to quickly lookup nodes by metadata properties. They are resource-intensive so use them sparingly and instead use graph traversal queries to find data, when possible. Instructions for creating and managing indexes can be found here: https://neo4j.com/docs/cypher-manual/current/administration/indexes-for-search-performance/.

## J. Integrate `check-dstat` Cloud Run with Pub/Sub
Follow instructions 1-3 in the "Integrating with Pub/Sub" section of the docs: https://cloud.google.com/run/docs/tutorials/pubsub#integrating-pubsub

Currently I don't think it's possible to automatically generate the pub/sub subscription since it requires Terraform to know the push endpoint of the dstat function, which is dynamically generated when the function is deployed by Cloud Build.

## K. Add Cloud SQL Client role to Cloud Functions service account
https://cloud.google.com/sql/docs/mysql/connect-functions

# predict-stocks
repository to store the final project of the MLOPs Zoomcamp of 2023

In this project I build a setup for running a model that predicts stock prices. 
The idea is to predict today's closing price by using the opening and closing 
prices of the last day stock trading was possible.

The training is executed locally with mlflow for experiment tracking. The model
is very simple and basically a dummy model for demonstration purposes. It uses 29 
days of opening and closing prices to train a random forest model. The stock data
is fetched with yfinance. 

To run the training you need to:
1) Install a virtual environment. I used pyenv, but you can use whatever you like. 
Just install the `requirements-dev.txt` file.
2) Next you need to start MLflow: 
`mlflow server \
--backend-store-uri sqlite:///mlflow.db \
--default-artifact-root s3://bucket-predict-stocks/models \
--host 0.0.0.0`
Note: Be aware that you have to setup configure your connection to AWS. You can just
export the required environmental variables or create a default profile. In addition,
you need to create a bucket called `bucket-predict-stocks` to store the models you train.
3) Navigate to `predict-stocks/predict-stocks/src` and execute `python train.py`. After 
the model is trained and uploaded it will appear in your S3 bucket and you can view
your experiments in the MLflow interface `http://0.0.0.0:5000/`.

The inference pipeline is deployed in the cloud via github actions and with infrastructure 
as code using terraform. The input variables for terraform are defined in 
`predict-stocks/infrastructure/vars/prod.tfvars`. In order to load the correct model you
will have to specify `model_dir` to the folder containing the artifacts stored by MLflow
on S3. After updating the `prod.tfvars file` you just have to push to the main branch and
everything will be done automatically. The lambda executing the prediction code is setup 
to run daily at 15.00. It is connected to prefect cloud to enable a nice overview. For this
to work you have to store your `PREFECT_API_KEY` and your `PREFECT_API_URL` in github in the
repository secrets section. For the connection between github actions and AWS, I setup a role
in the AWS cloud console which can be assumed by github actions. You can follow this guideline: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
or you also store your AWS credentials as repository secrets and slightly change github actions
workflow. For both options, make sure that your user or role has all required policies attached 
to it. Before starting with terraform you will also have to manually create a bucket to store
terraform states. I called it `terraform-states-cloud`.

The setup of the AWS lambda function is very similar to the lecture. I create the ECR as part of
the stack and have a null_resource to push the docker image. I liked this setup, because I can 
destroy the whole stack at once. I create a separate github actions workflow which can be 
triggered manually on the github page to destroy the stack (`remove-deployment.yml`).

Unfortunately, I did not have time to write a lot of test, but I setup a `ci-tests` workflow with
github actions which is running a dummy test if a pull request to main is created.

Here are some screenshot:
![mlflow.png](images%2Fmlflow.png)

![github_actions.png](images%2Fgithub_actions.png)

![aws_lambda.png](images%2Faws_lambda.png)

![prefect.png](images%2Fprefect.png)

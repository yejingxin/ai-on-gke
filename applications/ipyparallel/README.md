## Introduction

This guide walks you through the process of setting up a multi-host TPU cluster using Google Kubernetes Engine (GKE) and IPyParallel. By following these steps, you'll create a powerful distributed computing environment suitable for interactive development on a multi-host TPU cluster.

## Prerequisites
- Google Cloud Platform account with billing enabled
- gcloud CLI installed and configured
- kubectl installed
- Python 3.7+ installed
- Docker installed (for building the custom image)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli) installed

## Creating the IPyParallel Docker Image
1. Examine the example [Dockerfile](./tpu/Dockerfile). It installs `ipyparallel` and `jax` library, `ipyparallel` is required and `jax` is added for demo purpose.  You can expand the docker config as needed, for example replace `jax` with `pytorch xla` to run pytorch model.

1. Build the Docker image:
    ```
    docker build --network host -t your_image_name:tag .
    ```
1. Push the image to a container image repository. For example, to use GCP Artifact Registry, follow these [instructions](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling#pushing). 

1. Note the image URL, as you'll need it when setting the `docker_image` variable in Terraform.

## Creating a TPU GKE Cluster
### Using Terraform (Recommended)
1. Review the Terraform variables defined in [`variables.tf`](./tpu/variables.tf).
1. Modify the [`terraform.tfvars`](./tpu/terraform.tfvars) file with your specific configuration. For example:
    ```
    project_id             = "my_gcp_project"
    resource_name_prefix   = "great_notebook"
    region                 = "us-central2"

    tpu_node_pool = {
      zone         = "us-central2-b"
      node_count   = 2
      machine_type = "ct4p-hightpu-4t"
      topology     = "2x2x2"
    }

    filestore = {
      zone       = "us-central2-b",
      share_name = "ipp"
    }
    maintenance_interval = "AS_NEEDED"
    docker_image         = "gcr.io/tpu-prod-env-multipod/yejingxin_ipp_runner:test"
    jupyter_token = "abc123"
    ```
1. Navigate to the [`ai-on-gke/applications/ipyparallel/tpu`](./tpu/) directory and run:
    ```
    terraform init
    terraform apply
    ```
1. The cluster creation process takes about 5-10 minutes. Once complete, the following files will be generated in the same folder:
    - Notebook service manifests:
        - `preprov-filestore.yaml`
        - `deployment.yaml`
        - `service.yaml`
    - Bash script to manage the notebook service:
        - `ipp_notebook.sh`

## Start the service
1. Initialize the GKE cluster:
    ```
    bash ipp_notebook.sh init
    ```
    This obtains the cluster credentials and installs [LeaderWorkerSet](https://github.com/kubernetes-sigs/lws).

1. Start the notebook service:
    ```
    bash ipp_notebook.sh up
    ```
1. Access the notebook service via Colab:

    a) Forward the port:

      ```
      bash ipp_notebook.sh portforward
      ```

    it will print out the runtime URL for connection, like `http://127.0.0.1:8888/lab?token=abc123`

    b) Connect the example Colab notebook to the local [runtime](https://research.google.com/colaboratory/local-runtimes.html). In Colab, click "Connect" and select "Connect to local runtime...".

    c) Enter the URL from step a) and click "Connect".
### Interactive Development with Notebook
Follow the instructions provided in the notebook for interactive development.

## Clean Up

1. Stop the service
    ```
    bash ipp_notebook.sh down
    ```
1. Delete the cluster resources and generated scripts
    ```
    terraform destroy
    ```
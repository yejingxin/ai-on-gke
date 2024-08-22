## Introduction

This guide will walk you through the process of setting up a multi-host TPU cluster using Google Kubernetes Engine (GKE) and IPyParallel. By following these steps, you'll create a powerful distributed computing environment suitable for interactive development on multihost TPU cluster.

## Prerequisites
- Google Cloud Platform account with billing enabled
- gcloud CLI installed and configured
- kubectl installed
- Python 3.7+ installed
- Docker installed (for building the custom image)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli) installed

## Creating the IPyParallel Docker Image
Create a Dockerfile: 
```dockerfile
FROM python:3.10-slim-bullseye 

RUN pip install --upgrade pip

RUN pip install ipyparallel
RUN pip install -U "jax[tpu]" -f https://storage.googleapis.com/jax-releases/libtpu_releases.html

RUN mkdir -p /app/ipp
```
It installs `ipyparallel` and `jax` library, `ipyparallel` is required and `jax` is added for demo purpose.  Users can expand the docker config as needed.

Build the Docker image and push it to a container image repository:
```
docker build --network host .
```

## Creating a TPU GKE Cluster
### Using Terraform (Recommended)
Modify the terraform variables
```
project_id             = "<project_id>"
resource_name_prefix   = "<unique_name>"
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
docker_image         = "<image_url>"
jupyter_token = "abc123"
```
Run terraform within the folder of `ai-on-gke/applications/ipyparallel/tpu`
```
terraform init
terraform apply
```
Around 5-10 min, the cluster will be created, and all the manifests and tool are generated within the same folder, including
```bash
# three manifests to create notebook service
preprov-filestore.yaml
deployment.yaml
service.yaml
# bash script to manage the notebook service
ipp_notebook.sh
```
## Start the service
Run `bash ipp_notebook.sh init` to intall LeaderWorkerSet on the GKE cluster, and start the service by `bash ipp_notebook.sh up`. Once the service is started successfully, you can forward the port by `bash ipp_notebook.sh portforward`, and connect a [colab notebook](https://colab.research.google.com/drive/1vttX96LAwkhoVIhYA7pa2Nu_Gge7-gwY?resourcekey=0-uSIHyozG8aber-lhvyQHMg&usp=sharing#scrollTo=i1xjnqvOxbBQ) to the local runtime via `http://127.0.0.1:8888/lab?token=abc123`. 

## Clean Up

- The service can be tear up by `bash ipp_notebook.sh down`
- The cluster can be deleted by `terraform destroy`
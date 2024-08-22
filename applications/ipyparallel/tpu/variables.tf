variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "resource_name_prefix" {
  default     = ""
  description = "prefix for all the resouce naming"
}

variable "cpu_machine_type" {
  default     = "n1-standard-16"
  description = "CPU machine type for default GKE node pool"
}

variable "tpu_node_pool" {
  description = "tpu podslice config"
  type = object({
    zone         = string,
    node_count   = number,
    machine_type = string,
    topology     = string,
    disk_type    = optional(string),
    disk_size_gb = optional(number),
  })
}

variable "tpu_type_map" {
  type = map(any)
  default = {
    ct4p-hightpu-4t = "tpu-v4-podslice"
    ct5p-hightpu-4t = "tpu-v5p-slice"
    ct5lp-hightpu-4t = "tpu-v5-lite-podslice"
  }
}

variable "filestore" {
  description = "filestore config"
  type = object({
    zone       = string,
    share_name = string,
    }

  )
}

variable "maintenance_interval" {
  default     = "AS_NEEDED"
  description = "maintenance interval for TPU machines."
}

variable "docker_image" {
  description = "maintenance interval for TPU machines."
}
variable "jupyter_token" {
  description = "maintenance interval for TPU machines."
}
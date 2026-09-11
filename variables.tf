variable "kubeconfig_path" {
  type        = string
  description = "Caminho local do kubeconfig; não versionar."
}

variable "namespace" {
  type    = string
  default = "oficina"
}

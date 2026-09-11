# Oficina Kubernetes Infra

Infraestrutura Kubernetes declarada em Terraform. O módulo é deliberadamente compatível com kind, minikube ou Docker Desktop e não cria recursos cloud pagos.

```bash
terraform init -backend=false
terraform plan -var="kubeconfig_path=$HOME/.kube/config"
```

Nunca execute `apply` contra um cluster que não seja seu. Para remoto, configure state, OIDC, environments `homolog`/`prod`, proteção de `main` e a autorização de `soat-architecture`.

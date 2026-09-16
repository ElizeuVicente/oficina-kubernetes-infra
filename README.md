# Oficina Kubernetes Infra

Infraestrutura Kubernetes declarada em Terraform. O módulo é deliberadamente compatível com kind, minikube ou Docker Desktop e não cria recursos cloud pagos.

## Homologação local

Suba primeiro a API em `../oficina-tech-challenge` e a função em `../oficina-auth-lambda`; em seguida:

```bash
docker compose -f local/docker-compose.yml up -d
curl http://localhost:8000/actuator/health
```

Kong fica em `http://localhost:8000`, Prometheus em `http://localhost:9090` e Grafana em `http://localhost:3000`. O gateway limita a 60 requisições/minuto localmente e encaminha `/api` e `/auth/cpf`.

As regras locais ficam em `local/alerts.yml` e o dashboard técnico importável em `local/grafana-dashboard.json`.

```bash
terraform init -backend=false
terraform plan -var="kubeconfig_path=$HOME/.kube/config"
```

Nunca execute `apply` contra um cluster que não seja seu. Para remoto, configure state, OIDC, environments `homolog`/`prod`, proteção de `main` e a autorização de `soat-architecture`.

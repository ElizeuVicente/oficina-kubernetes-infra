#!/usr/bin/env sh
set -eu
KIND_BIN="${KIND_BIN:-kind}"
"$KIND_BIN" create cluster --name oficina
kubectl cluster-info --context kind-oficina

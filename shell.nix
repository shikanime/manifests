{ mkShell
, minikube
, skaffold
, kubectl
, kubernetes-helm
}:

mkShell {
  buildInputs = [
    minikube
    skaffold
    kubectl
    kubernetes-helm
  ];
}

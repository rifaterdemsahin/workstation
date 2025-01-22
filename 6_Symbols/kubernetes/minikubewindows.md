https://minikube.sigs.k8s.io/docs/start/

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install kubernetes-cli

choco install minikube
minikube start
kubectl get po -A


winget install -e --id Kubernetes.minikube
winget install -e --id PS.KubeDevDashboard

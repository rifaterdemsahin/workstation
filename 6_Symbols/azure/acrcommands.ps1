az account set --subscription 15704bda-bb65-45ef-bd84-55b56bb32733
az acr list -o table
az acr repository delete --name pipelines-devops-docker --resource-group Devops
az acr repository delete --name pipelines-devops-docker-gpu --resource-group Devops
az acr repository delete --name pipelines-devops-docker-msbuild --resource-group Devops

az acr repository delete --name pipelines-devops-docker --resource-group Devops


az acr repository delete -n devopspexabo --repository pipelines-devops-docker
az acr repository delete -n devopspexabo --repository pipelines-devops-docker-gpu -force
az acr repository delete -n devopspexabo --repository pipelines-devops-docker-msbuild -y

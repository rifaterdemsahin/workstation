https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal

az login

az login -SubscriptionName "XXX" 

az account set --subscription 15704bda-xxx


az aks get-credentials --resource-group XXX --name XXXX --admin

cd C:\project\workstation\kubernetes\mongodb_starter\

ls

kubectl apply -f mongo-secret.yaml

kubectl apply -f mongo.yaml

kubectl apply -f mongo-configmap.yaml

kubectl apply -f mongo-express.yaml

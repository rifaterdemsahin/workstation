poc for node app on docker kubernetes blue green deployment

initial part
install the minbikube

Windows boxes
choco install docker-engine
choco install docker-desktop

Docker part
docker build -t rifaterdemsahib/nodeapp . 
docker push rifaterdemsahib/nodeapp:latest 
kubectl apply -f deployment.yml
kubectl create -f deployment.yml 

repull part
kubectl get pods
kubectl delete pod nodeapp-deployment-5474484f79-mmb9k
kubectl get pods 132 history

Connect to the

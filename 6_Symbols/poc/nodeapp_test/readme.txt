poc for node app on docker kubernetes blue green deployment

> initial part
> install the minbikube

Windows boxes
choco install docker-engine
choco install docker-desktop
> restart
> check box check
docker run hello-world

Docker part
docker build -t rifaterdemsahib/nodeapp . 
> set experimental and restarrt / swith backendfort the stage

docker login
docker push rifaterdemsahib/nodeapp:latest 
minikube delete > of there is a conflict detected!
minikube start
minikube status
cat deployment.yml
> check it and see
kubectl apply -f deployment.yml
> OR  > kubectl create -f deployment.yml 

kubectl apply -f service.yml

kubectl get deployments
> Check deployment

minikube service --all
> Get url
http://192.168.49.2:31110/
http://192.168.49.2:31110/will
http://192.168.49.2:31110/ready
repull part
kubectl get pods
kubectl delete pod nodeapp-deployment-5474484f79-mmb9k
kubectl get pods 132 history

Connect to the

minikube delete \
minikube start \
cd C:\project\workstation\kubernetes\mongodb_starter\ \
ls \
kubectl apply -f mongo-secret.yaml \
kubectl apply -f mongo.yaml \
kubectl apply -f mongo-configmap.yaml \
kubectl apply -f mongo-express.yaml \
minikube service mongo-express-service

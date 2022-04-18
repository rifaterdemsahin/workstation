
#Cold stroage system already there \
kubectl apply -f mongo-secret.yaml \
kubectl get secret

#applied secrets than it can vbe used \
kubectl apply -f mongo.yaml

#terminal keep it open \
kubectl get pod --watch \

#services run it \
kubectl get service 

#get ip \
kubectl get pod -o wide 

#Implement config map as it is ok to apply after the secrets \
kubectl apply -f mongo-configmap.yaml 

#Send user interface \
kubectl apply -f mongo-express.yaml 

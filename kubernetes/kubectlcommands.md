#check  \
kubectl version \
 kubectl get pods -A \
 kubectl get nodes \
 kubectl get services \

#helloworld  \
 kubectl create deployment nginx-deployment --image=nginx \
 kubectl get deployment \
 kubectl get pod \

#edit yaml  \
 kubectl edit deployment nginx-deployment \
 
 #delete  \
 kubectl delete deployment nginx-deployment \

#scale  \
 kubectl get replicaset  \
 
 #debug  \ 
 kubectl get service \
 kubectl describe service mongo-express-service \ 
 kubectl logs nginx-deployment-794f656f8b-zks75  \
 kubectl exec -it nginx-deployment-794f656f8b-zks75  \


#bulk up  \
 kubectl apply -f deployment.yaml \
 kubectl delete -f deployment.yaml \


#orchestrate  \
kubectl apply -f .\deployment-nginx.yaml \
kubectl apply -f .\deployment-nginx-service.yaml \
kubectl apply -f .\deployment-nginx-replication-controller.yaml \


#service  \
 kubectl get service \
  kubectl describe service nginx \
  kubectl get pod -o wide \
  kubectl get deployment ngix-deployment \

#all  \
 kubectl get all \
 kubectl get secret \

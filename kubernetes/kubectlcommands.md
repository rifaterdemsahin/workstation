#check  \
kubectl version \
 kubectl get pods -A \
 kubectl get nodes \

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
 
 #debug  \ \
 kubectl logs nginx-deployment-794f656f8b-zks75  \
 kubectl exec -it nginx-deployment-794f656f8b-zks75  \


#bulk up  \
 kubectl apply -f deployment.yaml

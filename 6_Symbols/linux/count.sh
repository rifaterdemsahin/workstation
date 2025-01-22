mylist=($(az aks list))

for DISK in "${AKS_DISKS[@]}"
do
    echo "Attaching disk ${DISK} to VM ${AKS_VMS[${VM_INDEX}]}"
    $(az vm disk attach -g ${AKS_NODE_RESOURCE_GROUP} --vm-name ${AKS_VMS[${VM_I
NDEX}]} --name  ${DISK})
    let "VM_INDEX+=1"
done

resourcegroupname="statestoragerg19910"
location="northeurope"
storageAccountName="statestacc19910"
storageContainerName="statestoragecontainer"

az group create -n $resourcegroupname -l $location

az storage account create -n $storageAccountName -g $resourcegroupname -l $location --sku Standard_LRS

connectionString=$(az storage account show-connection-string -n $storageAccountName -g $resourcegroupname --query connectionString --output tsv)
az storage container create -n $storageContainerName --account-name $storageAccountName --connection-string $connectionString
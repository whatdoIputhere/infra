@echo off

set resourcegroupname="statestoragerg19910"
set location="northeurope"
set storageAccountName="statestacc19910"
set storageContainerName="statestoragecontainer"

call az group create -n %resourcegroupname% -l %location%

call az storage account create -n %storageAccountName% -g %resourcegroupname% -l %location% --sku Standard_LRS

for /f "delims=" %%a in ('az storage account show-connection-string -n %storageAccountName% -g %resourcegroupname% --query connectionString --output tsv') do set connectionString=%%a
call az storage container create -n %storageContainerName% --account-name %storageAccountName% --connection-string %connectionString%
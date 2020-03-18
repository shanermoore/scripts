Write-host "Enter OneView password at the prompt" -ForegroundColor Yellow
 Connect-HPOVMgmt -Hostname "" -UserName ""
 $VC = Read-Host "Enter vCenter name/ip to connect to" -ForegroundColor Cyan
 Connect-viserver $VC
 
 Get-HPOVStoragePool
 Write-host "For the next two questions refer to the data on screen" -ForegroundColor Yellow
 $Pool = Read-host "Enter the name of the Storage Pool to use for the new volume" 
 $System = Read-Host "Enter the name of the Storage System that Pool is on"
 $cap = Read-host "Enter the size of the volume in GB"
 $name = Read-Host "Enter the name of the new volume"
 $ID = Read-Host "Enter the Lun ID fo rthe new volume"
 $cluster = Read-Host "Enter VMware cluster to add datastore"

 $SP = Get-HPOVStoragePool -Name $Pool -StorageSystem $System
 New-HPOVStorageVolume -Name $name -StoragePool $SP -Capacity $cap -ProvisioningType Thin
 
$vol =  Get-HPOVStorageVolume -Name $name
# the *CA1ESX* will get all the host in the shared production cluster
# use *Tenant* to get all the host in the Cloud environment
$blades = Get-HPOVServerProfile -Name *CA1ESX*
Foreach ($svr in $blades) {
    New-HPOVServerProfileAttachVolume -ServerProfile $profile -Volume $vol -LunID $ID -LunIdType Manual | Wait-HPOVTaskComplete
    }
#scan all the host in the cluster to new storage volume
Get-Cluster $cluster | Get-VMHost | Get-VMHostStorage -RescanAllHba -RescanVmfs

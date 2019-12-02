#Setting Storage Luns to Round Robin 
$VC = Read-Host " Enter vCenter name:"

Connect-VIServer $VC 

Get-Cluster | Select name | FT
$Cluster = Read-Host " Enter Cluster name fron list above:"

$VMhosts = Get-cluster $cluster | Get-VMHost 
Foreach ($VMhost in $VMhosts) {
Write-Host "Setting Multipath Policy on $VMhost to Round Robin" -ForegroundColor Green
Get-VMHost $VMhost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy-notlike "RoundRobin"} | Set-Scsilun -MultiPathPolicy RoundRobin 
Get-VMhost $VMhost | Get-ScsiLun -LunType Disk | Where-Object {$_.CanonicalName-like ‘naa.*’ -and $_.MultipathPolicy-like ‘RoundRobin’} | Set-ScsiLun -CommandsToSwitchPath 1 
} 

Write-host "disconnecting from $VC" -ForegroundColor Yellow
Disconnect-VIServer -Server * -Confirm:$False

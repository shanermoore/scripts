$VC = Read-Host " Enter vCenter name:"
Connect-VIServer $VC  
$VMHosts = Get-cluster "Production" | Get-VMHost  
foreach ($VMHost in $VMHosts) {
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-219 -VLanId 219 
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-1201 -VLanId 1201
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-1300 -VLanId 1300 
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-217 -VLanId 217
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-103 -VLanId 103
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-104 -VLanId 104
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-105 -VLanId 105
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-106 -VLanId 106
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-107 -VLanId 107
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-112 -VLanId 112
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-118 -VLanId 118
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-2000 -VLanId 2000 
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-2001 -VLanId 201 
Get-VMHost -name $VMhost | Get-VirtualSwitch -name vswitch2 | New-VirtualPortGroup -name Name-1207 -VLanId 1207
} 
Disconnect-viserver -Server * -Confirm:$false ‍

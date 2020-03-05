#connect to Nimble, be sure to add your Nimble IP or FQDN in the ""
Write-Host "Connecting to Nimble" -ForegroundColor Green
Connect-NSGroup "" -IgnoreServerCertificate -Credential admin 

#VMWare performance policy ID
$id = "0366971348fab73f4b000000000000000000000014" 

#Initiator Groups (per host)
$CMH001 = "0266971348fab73f4b000000000000000000000007"
$CMH002 = "0266971348fab73f4b000000000000000000000008" 
$CMH003 = "0266971348fab73f4b000000000000000000000009"
$CMH004 = "0266971348fab73f4b00000000000000000000000a"

$name = Read-Host "Enter Datastore Name"
$size = Read-Host "Enter Datastore Size in MB"

New-NSVolume -name $name -size $size -perfpolicy_id $id -thinly_provisioned $true -online $true

#remove charactors in the volume id so they are usable
$vol = Get-NSvolume -name "test2" | select ID
$id = $vol -replace "@{id=","" -replace "}", ""

#add new volume to initiator groups
New-NSAccessControlRecord -vol_id $id -apply_to both -initiator_group_id $CMH001 -lun 4
New-NSAccessControlRecord -vol_id $id -apply_to both -initiator_group_id $CMH002 -lun 4
New-NSAccessControlRecord -vol_id $id -apply_to both -initiator_group_id $CMH003 -lun 4
New-NSAccessControlRecord -vol_id $id -apply_to both -initiator_group_id $CMH004 -lun 4

#connect to vmware to create datastore
Write-host "Connecting to vCenter" -ForegroundColor Green
Connect-viserver 192.168.151.2 -User administrator@vsphere.local

#rescan host for new storage
Get-VMHost  | Get-VMHostStorage -RescanAllHba -Refresh

#function to find free LUNs found at http://vcloud-lab.com/entries/powercli/find-free-or-unassigned-storage-lun-disks-on-vmware-esxi-server
# removed some of the notes to save space
function Get-FreeEsxiLUNs {   
    #EXAMPLE
    #Get-FreeEsxiLUNs -Esxihost Esxi001.vcloud-lab.com
    #Shows free unassigned storage Luns disks on Esxi host name Esxi001.vcloud-lab.com
    ###############################

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [System.String]$Esxihost
    )    
    Begin {
        if (-not(Get-Module vmware.vimautomation.core)) {
            Import-Module vmware.vimautomation.core
        }
        #Connect-VIServer | Out-Null
    }
    Process {
        $VMhost = Get-VMhost $EsxiHost
        $AllLUNs = $VMhost | Get-ScsiLun -LunType disk
        $Datastores = $VMhost | Get-Datastore
        foreach ($lun in $AllLUNs) {
            $Datastore = $Datastores | Where-Object {$_.extensiondata.info.vmfs.extent.Diskname -Match $lun.CanonicalName}
            if ($Datastore.Name -eq $null) {
                $lun | Select-Object CanonicalName, CapacityGB, Vendor        
            } 
        }
    }
    End {}
}

$free = Get-FreeEsxiLUNs -Esxihost (get-vmhost | Get-random) | Where-Object {$_.Vendor -eq "Nimble"} |select CanonicalName
$path = $free -replace "@{CanonicalName=","" -replace "}",""


#create new Datastore
Get-VMHost| Get-Random | New-Datastore -name "test" -Path $path -Vmfs -FileSystemVersion 6

#rescan vhost for new Datastore
Get-VMHost  | Get-VMHostStorage -RescanAllHba -Refresh

#Disconnect from Nimble and vCenter
Disconnect-NSGroup 
Disconnect-VIServer -Server * -confirm:$false

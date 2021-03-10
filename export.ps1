#$VC = Read-Host "Enter vCenter Name /IP"
#Connect-VIServer -$VC

#Get Data from Source vCenter
#Built to be used with Set-SourceSettings.ps1 to recreate those same settings in another vCenter.
#Does not support vApps or multiple datacenters in the same vCenter.
param
(
        $directory = $(read-host "Enter local output directory"),
        $datacenter = $(read-host "Enter datacenter"),
        [switch]$getTemplates
)
#Takes a VI Folder object and returns an array of strings that represents that folder's absolute path in the inventory
function get-folderpath
{
        param
        (
                $thisFolder
        )
        #Creates an array of folders back to the root folder
        if ($thisFolder.id -like "Folder*")
        {
                $folderArray = @()
                $folderArray += $thisFolder
                while ($folderArray[-1].parent.parent.id -match "Folder")
                {
                        $folderArray += $folderArray[-1].parent
                }
                [array]::Reverse($folderArray)
                #convert the array of folders to an array of strings with just the folder names
                $folderStrArray = @()
                $folderArray | %{$folderStrArray += $_.name}
                $folderStrArray
        }
        else
        {
                write-error "Unexpected input provided; does not appear to be a Folder."
        }
}

$directory = $directory.trim("\") #" This comment is to fix the gistit syntax highlighting.
new-item $directory -type directory -erroraction silentlycontinue

if ((get-datacenter).count -gt 1){write-error "These scripts do not support multiple Datacenters in a single inventory"}

#Get Roles
get-virole | ? {$_.issystem -eq $false} | export-clixml $directory\$($datacenter)-roles.xml

#Get Permissions
$allPermissions = @()
$foundPermissions = get-vipermission
$i = 0
foreach ($thisPermission in $foundPermissions)
{
        write-progress -Activity "Getting permissions" -percentComplete ($i / $foundPermissions.count * 100)
        $objPerm = "" | select entity,type,Role,Principal,Propagate,folderType
        $objPerm.type = $thisPermission.entity.id.split("-")[0]
        $objPerm.Role = $thisPermission.role
        $objPerm.Principal = $thisPermission.Principal
        $objPerm.Propagate = $thisPermission.propagate
        #Create an absolute path for a folder, otherwise store the name of the entity
        if ($objPerm.type -eq "Folder")
        {
                $objPerm.entity = get-folderpath $thisPermission.entity
                $objPerm.folderType = $thisPermission.entity.type
        }
        else
        {
                $objPerm.entity = $thisPermission.entity.name
                $objPerm.folderType = ""
        }
        $allPermissions += $objPerm
        $i++
}
$allPermissions | export-clixml $directory\$($datacenter)-permissions.xml


#Get VM Folder Structure
$outFolders = @()
$i = 0
$foundFolders = get-datacenter $datacenter | get-folder | ? {$_.type.tostring() -eq "VM" -and $_.parent.id -notLike "Datacenter*"}
foreach ($thisFolder in $foundFolders)
{
        write-progress -Activity "Getting VM folder structure" -percentComplete ($i / $foundFolders.count * 100)
        $myFolder = "" | select path
        $myFolder.path = get-folderpath $thisFolder
        $outFolders += $myFolder
        $i++
}
$outFolders | export-clixml $directory\$($datacenter)-folders.xml

#Convert Templates to VMs (so that they can transition vCenters)
get-template | select name | export-clixml $directory\$($datacenter)-Templates.xml
if ($getTemplates){get-datacenter $datacenter | get-template | set-template -ToVM -confirm:$false}

#Get VM Locations
$outVMs = @()
$allVApps = get-datacenter $datacenter | get-vapp
$vAppVMs = $allVApps | get-vm
if ($vAppVMs)
{
        $allVMs = Get-VM | ? {!($vAppVMs.contains($_))}
        #Deal with vApps... maybe try this guy's technique to capture settings and make a best effort at recreating the vApp?
        # http://www.lukaslundell.com/2013/06/modifying-vapp-properties-with-powershell-and-powercli/
        $outVApps = @()
        foreach ($thisVApp in $allVApps)
        {
                write-error "Discovered VAPP: $($thisVApp.name) - vAPPs must be recreated manually."
                $myVApp = "" | select name,VMs
                $myVApp.name = $thisVApp.name
                $myVApp.VMs = ($thisVApp | get-vm).name
                $outVApps += $myVApp
        }
        $outVApps | export-clixml $directory\$($datacenter)-vApps.xml
}
else
{
        $allVMs = get-datacenter $datacenter | get-VM
}
$i = 0
foreach ($thisVM in $allVMs)
{
        write-progress -Activity "Getting VM locations" -percentComplete ($i / $allVMs.count * 100)
        $myVM = "" | select name,folderPath
        $myVM.name = $thisVM.name
        if ($thisVM.folder.name -eq "VM")
        {
                $myVM.folderPath = $NULL
        }
        else
        {
                $myVM.folderPath = get-folderpath $thisVM.folder
        }
        $outVMs += $myVM
        $i++
}
$outVMs | export-clixml $directory\$($datacenter)-VMs.xml


Disconnect-VIServer -Server * -Confirm:$false

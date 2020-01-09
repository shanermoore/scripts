Function Move-CrossVC
{
########################################################################################################################################
# Move-CrossVC                                                                                                                         #
# Updated by: Shane Moore 12/20/2019                                                                                                   #
# Revision 1.1 12/26/2019                                                                                                              #
# Revision 1.2 1/8/2019                                                                                                                #
# Core code by VMware and the PSxVCvMotion module link here: https://code.vmware.com/samples/2060/psxvcvmotion---cross-vcenter-vmotion #
########################################################################################################################################

# making sure Pester is installed and Getting variable information
Import-Module Pester
$sourceVC = Read-Host " Enter Source vCenter Name" 
$DestVC = Read-Host " Enter Destination vCenter Name"
$vmname = Read-host " Enter VM name to Migrate"
$sourceCluster = Read-Host " Enter Source Cluster Name"
$destCluster = Read-Host " Enter Destination Cluster Name"
$sourcePG = Read-Host " Enter Source Port Group (Network) information"
$DestPG = Read-Host " Enter Destination Port Group (Network) information"
$destSwitch = Read-Host " Enter Destination Virtual Switch Name"
$PG = $sourcePG, $DestPG
$sourceDS = Read-Host " Enter Source Datastore"
$destDS = Read-Host " Enter Destination DataStore"
$DS = $sourceDS, $destDS

# Clear Screen and start the stopwatch
cls
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch 
$stopwatch.Start()

#Creating connection to both vCenters
Write-Host "Connecting to Source and Destination vCenters" -ForegroundColor Yellow
Do {
    # Loop until we get a valid userid/password and can connect, or some other kind of error occurs
    $Cred = Get-Credential -Message "Enter $SourceVC Credentials"
    $ConResult = Connect-VIServer -Server $SourceVC -Credential $Cred -ErrorAction SilentlyContinue -ErrorVariable Err
    If ($Err.Count -gt 0) {
        # Some kind of error, figure out if its a bad password
        If ($Err.Exception.GetType().Name -eq "InvalidLogin") {
            Read-Host "Incorrect user name or password, hit any key to try again or <Ctrl><C> to exit" 
        }
        Else {
            # Something else went wrong, just display the text and exit
            $Err.Exception
            Break
        }
    }
    Else {
        Read-Host "User name and password are valid"
        Connect-VIServer $SourceVC -Credential $Cred
    }
}
Until ($Err.Count -eq 0)

Do {
    # Loop until we get a valid userid/password and can connect, or some other kind of error occurs
    $Cred = Get-Credential -Message "Enter $destVC Credentials"
    $ConResult = Connect-VIServer -Server $destVC -Credential $Cred -ErrorAction SilentlyContinue -ErrorVariable Err
    If ($Err.Count -gt 0) {
        # Some kind of error, figure out if its a bad password
        If ($Err.Exception.GetType().Name -eq "InvalidLogin") {
            Read-Host "Incorrect user name or password, hit any key to try again or <Ctrl><C> to exit" 
        }
        Else {
            # Something else went wrong, just display the text and exit
            $Err.Exception
            Break
        }
    }
    Else {
       Read-Host "User name and password are valid"
        Connect-VIServer $destVC -Credential $Cred
    }
}
Until ($Err.Count -eq 0)



$VM = Get-Cluster $sourceCluster -Server $sourceVC | Get-VM $vmname -Server $sourceVC -erroraction SilentlyContinue 

Describe -Name 'Testing vSphere Infrastructure' {
    Context -Name 'Checking vCenters for Cross-vCenter vMotion compatibility' {
        It -Name "Source and destination vCenter version are compatible with Cross vCenter vMotion (minimum 6.0)" {
            #($sourceVC.Version -ge [version]'6.0') -and ($destVC.Version -ge [version]'6.0') | Should Be $True
        }

        If ($sourceVC.Version -eq [version]'6.5') {
            It -Name "If source version equals 6.5, destination version should not be 6.0" {
                ($destVC.Version -eq [version]'6.0') | Should Be $false
            }
        }
    }

    Context -Name 'Testing Clusters translation table' {
        foreach ($cluster in $sourceCluster) {
            It "Source cluster $($SourceCluster) exists" {
                {Get-Cluster -Name $sourceCluster -Server $sourceVC} | Should Not Throw
            }
            It "Destination cluster $($DestCluster) exists" {
                {Get-Cluster -Name $DestCluster -Server $destVC} | Should Not Throw
            }
        }
    }

    Context -Name 'Testing VMHosts' {

        $sourceVMHosts = @()

        foreach ($cluster in $SourceCluster) {
            $sourceVMHosts += Get-Cluster -Name $sourceCluster -Server $sourceVC -ErrorAction SilentlyContinue | Get-VMHost -ErrorAction SilentlyContinue
        }

        $destinationVMHosts = @()

        foreach ($cluster in $DestCluster) {
            $destinationVMHosts += Get-Cluster -Name $destCluster -Server $destVC -ErrorAction SilentlyContinue | Get-VMHost -ErrorAction SilentlyContinue
        }

        It -Name "Source cluster contains VMhosts" {
            $sourceVMHosts.Count | Should BeGreaterThan 0
        }

        Foreach ($VMHost in $sourceVMHosts) {
            It -Name "Source VMHost $($VMHost.Name) version is compatible with Cross-vCenter vMotion (minimum 6.0)" {
                $VMHost.Version -ge [version]'6.0' | Should Be $True
            }
        }

        It -Name "Destination cluster contains VMhosts" {
            $destinationVMHosts.Count | Should BeGreaterThan 0
        }

        Foreach ($VMHost in $destinationVMHosts) {
            It -Name "Destination VMHost $($VMHost.Name) version is compatible with Cross vCenter vMotion (minimum 6.0)" {
                $VMHost.Version -ge [version]'6.0' | Should Be $True
            }
        }
    }

    Context -Name "Testing VMs" {
        It -Name "Found VM matching scope $($vmname)" {
            $VM.count | Should BeGreaterThan 0
        }
    }

    If ($PG) {
        Context -Name 'Testing Portgroups translation table' {
            Foreach ($portgroup in $PG) {

                $sourcePortgroup = Get-VirtualPortGroup -Name $sourcePG -Server $sourceVC -ErrorAction SilentlyContinue

                It -name "Source portgroup $($sourcePG) exists" {
                    $sourcePortgroup.count | Should BeGreaterThan 0
                }

                $Destinationportgroup = Get-VirtualPortGroup -Name $destPG -Server $destVC -ErrorAction SilentlyContinue

                It -name "Destination portgroup $($destPG) exists" {
                    $Destinationportgroup.count | Should BeGreaterThan 0
                }

                If ($sourcePortgroup.ExtensionData.Key -like 'dvportgroup-*') {
                    It -name "If source portgroup is a vds, destination can't be a vss" {
                        ($sourcePortgroup.ExtensionData.Key -like 'dvportgroup-*') -and ($Destinationportgroup.ExtensionData.Key -notlike 'dvportgroup-*') | Should Be $False
                    }
                }
            }
        }
    }

    If ($DS) {
        Context -Name 'Testing Datastores translation table' {
            Foreach ($datastore in $DS) {
                It -name "Source datastore $($sourceDS) exists" {
                    {Get-Datastore -Name $sourceDS -Server $sourceVC} | Should Not Throw
                }
                It -name "Destination datastore $($destDS) exists" {
                    {Get-Datastore -Name $destDS -Server $destVC} | Should Not Throw
                }
            }
        }
    }
}


Write-host " Powering off $vm" -ForegroundColor Yellow
Try{
   $vmm = Get-VM -Name $vmName -ErrorAction Stop
   switch($vmm.PowerState){
   'poweredon' {
  Shutdown-VMGuest -VM $vm -Confirm:$false
   while($vmm.PowerState -eq 'PoweredOn'){
  sleep 5

   $vmm = Get-VM -Name $vmName
   }
   }
   Default {
   Write-Host "VM '$($vmName)' is not powered on!" -ForegroundColor Yellow
   }
   }
   Write-Host "$($vmName) has shutdown. It should be ready for Migration to $destVC." -ForegroundColor Green
}

Catch{

   Write-Host "VM '$($vmName)' not found!" -ForegroundColor Red

}

Sleep 10
$vm = Get-VM $vmname -Server $sourceVC
$Destination = Get-VMHost -Location $destCluster -Server $DestVC | Get-Random
$NetworkAdapter = Get-NetworkAdapter -VM $vm -Server $sourceVC
$VMPG = Get-VirtualPortGroup -VirtualSwitch $destSwitch -Name $DestPG -Server $destVC
$DS = Get-Datastore -Name $destDS -Server $destVC

Write-Host " Moving $vm from $sourceVC to $destVC. $vm will be in the $destCluster on host $destination. Please Stand By...." -ForegroundColor yellow

Move-VM $vm -Destination $Destination -NetworkAdapter $NetworkAdapter -PortGroup $VMPG -Datastore $DS -Confirm:$false

Sleep 5

Write-Host " Powering on $vm and waiting for VM Tools to start" -ForegroundColor Green
Start-VM $vmname -Server $DestVC

do {
$toolsStatus = (Get-VM $vmname | Get-View).Guest.ToolsStatus
write-host $toolsStatus
sleep 3
} until ( $toolsStatus -eq ‘toolsOk’ )

#Update vmware tools 
Write-Host " Checking and upgrading VMware Tools and VM Copatibility if nesessary" -ForegroundColor Yellow
 Get-VM $vmname | % { get-view $_.id } |Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNeedUpgrade"} |select name, @{Name=“ToolsVersion”; Expression={$_.config.tools.toolsversion}}, @{ Name=“ToolStatus”; Expression={$_.Guest.ToolsVersionStatus}}| Update-Tools -NoReboot -VM {$_.Name} -Verbose 

Write-Host " Rebooting $vmname after VM Compatibility Upgrade"
Restart-VM -VM $vmname -Server $DestVC -Confirm:$false
do {
$toolsStatus = (Get-VM $vmname | Get-View).Guest.ToolsStatus
write-host $toolsStatus
sleep 3
} until ( $toolsStatus -eq ‘toolsOk’ )

$StopWatch.Stop()
#Calculating Migration Time
$migrationTime = [math]::Round(($StopWatch.Elapsed).TotalMinutes ,2)

Write-Host " $vm is ready to use. Migration is Complete" -ForegroundColor Green
Write-Host " Total Migration time for $vmname was $migrationtime minutes" -ForegroundColor Cyan
sleep 2
Write-Host " Disconnecting from vCenters $sourceVC and $destVC" -ForegroundColor Yellow
Disconnect-VIServer -Server * -Confirm:$false

}

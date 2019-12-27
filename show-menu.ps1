function Show-Menu
{
    param (
        [string]$Title = 'Select Script'
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Yellow
    Write-Host "1: Press '1' to list all the Edge Gateway for each vCloud org." -ForegroundColor Yellow
    Write-Host "2: Press '2' to Create a new Tenant in vCloud Director" -ForegroundColor Yellow
    Write-Host "3: Press '3' to Get Virtual Machine Information" -ForegroundColor Yellow
    Write-Host "4: Press '4' to get Capacity Information for the Clusters in a vCenter" -ForegroundColor Yellow
    Write-Host "5: Press '5' to Set All FC Datastores Multipathing to Round Robin" -ForegroundColor Yellow
    Write-Host "6: Press '6' to Change the number of vCPU of a VM" -ForegroundColor Yellow
    Write-Host "7: Press '7' to Change the amount of Memory of a VM" -ForegroundColor Yellow
    Write-Host "Q: Press 'Q' to quit." -ForegroundColor Yellow
}
 
Function Get-VDCEdge {
Import-Module VMware.VimAutomation.Cloud, PowerNSX
Connect-CIServer 192.168.151.13
Connect-NsxServer -vCenterServer 192.168.151.9

$Orgs = Get-Org
$Edges = Get-NsxEdge

$myView = @()
Foreach ($Edge in $Edges) {
    $Report = [PSCustomObject] @{
            EdgeName = $Edge.Name
            VcdOrg = ($orgs | where {$_.Id -match $edge.Tenant}) 
       }
    $MyView += $Report
}

$MyView | Sort UpdateAvailable, VcdOrg | ft -AutoSize

Disconnect-NsxServer -confirm:$false
Disconnect-CIServer -Server * -Confirm:$false

}
Function New-Tenant {

$Client = Read-Host " Enter Client Name:"
$CPUMhz = Read-Host " Enter Amount of CPU needed in Ghz"
$MemGB = Read-Host " Enter amount of Ram needed in GB"
$StoGB = Read-host " Enter amount of Storage needed in GB"

#Getting Credentials for VCSA and vCD
$vcsacred = Get-Credential -Message "Enter vCenter Credentials:"
$vcdcred = Get-Credential -Message "Enter vCloud Director Credentials:"

#connecting to VCSA and vCD
Write-host " Connecting to vCenter and vCloud Director" -ForegroundColor Yellow
Connect-viserver 192.168.151.9 -Credential $vcsacred
Connect-ciserver 192.168.151.13 -Credential $vcdcred

#Creating required Ditributed Port Groups for vCD
$ExDVPG = Read-Host " Enter External Distributed Port Group Name" 
$ExDVPGvLAN = Read-Host " Enter vLAN ID for $ExDVPG "
Write-Host " Creating $ExDVPG with vLAN ID $ExDVPGvLAN " -ForegroundColor Yellow
Get-VDSwitch -Name "TenantDVSwitch01" | New-VDPortgroup -Name $ExDVPG -NumPorts 24 -VLanId $ExDVPGvLAN

$InDVPG = Read-Host " Enter Internal Distributed Port Group Name"
$InDVPGvLAN = Read-Host " Enter vLAN ID for $InDVPG "
Write-Host " Creating $InDVPG with vLAN ID $InDVPGvLAN " -ForegroundColor Yellow
Get-VDSwitch -Name "TenantDVSwitch01" | New-VDPortgroup -Name $InDVPG -NumPorts 24 -VlanId $InDVPGvLAN

#Create Org in vCD
Write-host " Creating Org and vDC for $client" -ForegroundColor Yellow
$PVDC = "Edafio CLoud"
New-Org -Name $Client 
#Create vDC for new Org
New-OrgVdc -Name $Client -Org $Client -ProviderVdc $PVDC -AllocationModelAllocationPool -CpuAllocationGHz $CPUMhz -MemoryAllocationGB $MemGB -StorageAllocationGB $StoGB

#Create Network pool

#create External Network

#create Edge GW




Write-host " Disconnecting from vCenter and vCloud Director" -ForegroundColor Yellow
Disconnect-VIServer -Server * -Confirm:$false
Disconnect-CIServer -Server * -Confirm:$false

}
Function Get-VMinfo {

$VC = Read-Host " Enter vCenter name"
Connect-VIServer $VC

#Add VM properties for vmtools version
Write-Host "Adding VM Properties for vmtools" -ForegroundColor Yellow
New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force 
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force

#Get VM info
Write-Host "Gathering VM info" -ForegroundColor Yellow
get-cluster | Get-VM | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}, @{N='FQDN';E={$_.ExtensionData.Guest.IPStack[0].DnsConfig.HostName, $_.ExtensionData.Guest.IPStack[0].DnsConfig.DomainName -join '.'}}, Guest, Version, ToolsVersion, ToolsVersionStatus, PowerState, NumCpu, MemoryGB, ProvisionedSpaceGB, UsedSpaceGB | Export-Csv F:\Powercli\Inventory\13.VMinfo.csv -NoTypeInformation 

Disconnect-VIServer -Server * -Confirm:$false

 }
Function Get-Capacity {
 
param ([System.Management.Automation.SwitchParameter] $PassThru)

Import-Module PScribo -Force;

Add-Type -AssemblyName system.speech
$synthesizer = New-Object system.Speech.Synthesis.SpeechSynthesizer
$synthesizer.SelectVoice('Microsoft Zira Desktop')

#$synthesizer.Speak('Enter Report Name')
$ReportName = "vSphere Capacity and Performance Report"

#$synthesizer.Speak('Enter Company Name')
$CompanyName = Read-Host "Enter Company Name"

#$synthesizer.Speak('Enter Author Name')
$Author = Read-Host "Enter Author Name"

#$synthesizer.Speak('Enter Version Number')
$Version = Read-Host "Enter Version Number"

#$synthesizer.Speak('Enter vCenter Name or IP')
$vc = Read-Host "Enter vCenter Name/IP"

#$synthesizer.speak('Enter vCenter User Name')
#$user = Read-Host "Enter vCenter User Name"

#synthesizer.speak('Enter vCenter Password')
#$pass = Read-Host "Enter vCenter Password" 



#$synthesizer.Speak('Building Documentation')
<# The document name is used in the file output #>
$document = Document $ReportName -Verbose {
    <#  Enforce uppercase section headers/names
        Enable automatic section numbering
        Set the page size to US Letter with 0.5inch margins #>
    $DefaultFont = 'Calibri'

    #region VMware Document Style
    DocumentOption -EnableSectionNumbering -PageSize Letter -DefaultFont $DefaultFont -MarginLeftAndRight 40 -MarginTopAndBottom 50

    Style -Name 'Title' -Size 22 -Color '002538' -Align Center
    Style -Name 'Title 2' -Size 18 -Color '007CBB' -Align Center
    Style -Name 'Title 3' -Size 12 -Color '007CBB' -Align Left
    Style -Name 'Heading 1' -Size 16 -Color '007CBB' 
    Style -Name 'Heading 2' -Size 14 -Color '007CBB' 
    Style -Name 'Heading 3' -Size 12 -Color '007CBB' 
    Style -Name 'Heading 4' -Size 11 -Color '007CBB' 
    Style -Name 'Heading 5' -Size 10 -Color '007CBB'
    Style -Name 'H1 Exclude TOC' -Size 16 -Color '007CBB' 
    Style -Name 'Normal' -Size 10 -Color '565656' -Default
    Style -Name 'TOC' -Size 16 -Color '007CBB' 
    Style -Name 'TableDefaultHeading' -Size 10 -Color 'FAF7EE' -BackgroundColor '002538' 
    Style -Name 'TableDefaultRow' -Size 10 
    Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'D9E4EA' 
    Style -Name 'Critical' -Size 10 -BackgroundColor 'FFB38F'
    Style -Name 'Warning' -Size 10 -BackgroundColor 'FFE860'
    Style -Name 'Info' -Size 10 -BackgroundColor 'A6D8E7'
    Style -Name 'OK' -Size 10 -BackgroundColor 'AADB1E'

    TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '002538' -Align Left -BorderWidth 0.5 -Default
    TableStyle -Id 'Borderless' -BorderWidth 0

    # VMware Cover Page
    BlankLine -Count 4
    Paragraph -Style Title $ReportName
    Paragraph -Style Title2 "Prepared for $CompanyName"
        BlankLine -Count 36
        Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
                'Author:'  = $Author
                'Date:'    = Get-Date -Format 'dd MMMM yyyy'
                'Version:' = $Version
                })

    PageBreak;

    # Table of Contents
    TOC -Name 'Table of Contents'
    PageBreak;


#Sets up paths and variables.
$vcenters = $VC 
$output = @()
$capacity = @()
$captable = @()
$cpuready = @()
$vmcpuready = @()
$scriptpath = "F:\powercli"
$listpath = "$scriptpath\PscriboCapacity\serverlists"
$outfile = "$scriptpath\PScriboCapacity\Reports\capacity_$CompanyName.csv"
#$vCPUTargetRatio = read-host "vCPU to pCPU Target Ratio?"
#$vRAMTargetRatio = read-host "vRAM to pRAM Target Ratio?"
$vCPUTargetRatio = 5
$vRAMTargetRatio = 1

connect-viserver $vc
$synthesizer.Speak('Log in with administrator credentials at the prompt')



#Gets CPU, RAM, and Storage allocation values and calculates ratios.
foreach ($item in Get-Cluster) {

	$vmcpuready = $null
	$vmcpuready = @()
	$cpuready = $null
	$cpurdytop10 = $null
	$cpurdytop10ave = $null

	#Connect to correct vCenter based on input file.
	#if (($global:DefaultViServers).Name -ne $vc) {
	#disconnect-viserver * -confirm:$false -ErrorAction SilentlyContinue
	#connect-viserver $vc
	#}


#Get hosts from clusters.
write-host "Get hosts from $item" -ForegroundColor Yellow
$vmhosts = Get-Cluster $item | get-vmhost
$vms = $vmhosts | Get-VM
$pwronvms = $vms | where {$_.PowerState -eq "PoweredOn"}

#Gather physical stats and VM data from hosts.
#CPU
write-host "Gather CPU stats from $item" -ForegroundColor Yellow
$pCPU = $vmhosts | Measure-Object NumCpu -Sum
$pCPU = $pCPU.Sum
$vCPUCap = ($pCPU * $vCPUTargetRatio)
#RAM
write-host "Gather RAM stats from $item" -ForegroundColor Yellow
$pRAM = $vmhosts | Measure-Object MemoryTotalGB -Sum
$pRAM = $pRAM.Sum
$vRAMCap = ($pRAM * $vRAMTargetRatio)
#Storage
write-host "Gather Storage stats from $item" -ForegroundColor Yellow
$ds = get-cluster $item | get-datastore | Select Name, CapacityGB, FreeSpaceGB
$PhysCap = $ds | where-object {$_.Name -NotLike "*local*"} | measure-object CapacityGB -Sum
$PhysCap = $PhysCap.Sum


#Calculate vCPU values for Powered On only.
write-host "Measure and calculate stats." -ForegroundColor Yellow
$vCPU = $vms | where-object {$_.PowerState -eq "PoweredOn"} | measure-object NumCPU -Sum
$vCPU = $vCPU.Sum
#Calculate vCPU to pCPU ratio for Powered On VMs.
$vCPURatio = ([math]::round($vCPU / $pCPU,1))
$vCPURatio = "{0:N1}" -f $vCPURatio
$vCPURemaining = ($vCPUCap - $vCPU)

#Calculate vRAM allocation and compares to physical RAM

#Calculate vRAM values Powered On VMs
$vRAM = $vms | where-object {$_.PowerState -eq "PoweredOn"} | measure-object MemoryGB -Sum
$vRAM = $vRAM.Sum
#Calculate vRAM to pRAM Ratio (Powered On)
$vRAMRatio = ([math]::round($vRAM / $pRAM,1))
$vRAMRatio = "{0:N1}" -f $vRAMRatio
$vRAMRemaining = ($vRAMCap - $vRAM)

#Storage usage for All VMs.
$ProvSpace = $vms | measure-object ProvisionedSpaceGB -Sum
$ProvSpace = $ProvSpace.Sum
$UsedSpace = $vms | measure-object UsedSpaceGB -Sum
$UsedSpace = $UsedSpace.Sum
$FreeSpace = $ds | where-object {$_.Name -NotLike "*local*"} | measure-object FreeSpaceGB -Sum
$FreeSpace = $FreeSpace.Sum
$ProvPercent = ([math]::round(($ProvSpace / $PhysCap) * 100,1))

	#Calculate average CPU Ready over past 7 days.
	#Loop through the VM list and gather stats for each Powered On VM.
	foreach ($vm in $vms | where {$_.PowerState -eq "PoweredOn"}) {
		$tempcpurdy = $null
		$tempcpurdyave = $null
		#Capture stats.
		write-host "Calculate CPU Ready stats for $vm." -ForegroundColor Green
		$tempcpurdy = get-stat -entity $vm -stat cpu.ready.summation -start (get-date).adddays(-7) -intervalmins 30 -instance ""
		#Calculate average for time period and convert to % value.
		#Average divided by 30 minute interval converted to milliseconds, multiply by 100 and divide by number of CPU's.
		$tempcpurdyave = ([math]::round((((($tempcpurdy | measure-object value -ave).average) / 1800000) * 100) / $vm.NumCPU,2))
		#Add average to array, reject values that are less than 0.01%.
		$vmcpuready += ($tempcpurdyave | where {$_ -ge .01})
		#Repeat for next VM.
	}

	#Calculate average of all VMs on cluster.
	write-host "Aggregate CPU ready values from $item" -ForegroundColor Yellow
	$cpuready = ([math]::round(($vmcpuready | measure-object -ave).average,2))
	# $cpureadymax = ([math]::round(($vmcpuready | measure-object -max).maximum,2))
	$cpurdytop10 = $vmcpuready | sort -desc | select -first ([math]::round($vmcpuready.count * .1,0))
	$cpurdytop10ave = ([math]::round(($cpurdytop10 | measure-object -ave).average,2))
		if ($vms.count -eq 0) {
			$cpuready = 0
			$cpurdytop10ave = 0
		}


#Adds counts and ratios to table.
write-host "Add values to table for $item" -ForegroundColor Green
$capacity = New-Object PSObject
$capacity | Add-Member -MemberType Noteproperty "Cluster" -value $item
$capacity | Add-Member -MemberType Noteproperty "Total # of Hosts" -value $vmhosts.count
$capacity | Add-Member -MemberType Noteproperty "Total # of VMs" -value $pwronvms.count
$capacity | Add-Member -MemberType Noteproperty "vCPURatio" -value "$vCPURatio`:1"
$capacity | Add-Member -MemberType Noteproperty "pCPU" -value $pCPU
$capacity | Add-Member -MemberType Noteproperty "vCPU" -value $vCPU
$capacity | Add-Member -MemberType Noteproperty "vCPU Cap" -value $vCPUCap
$capacity | Add-Member -MemberType Noteproperty "vCPU Remaining" -value $vCPURemaining
$capacity | Add-Member -MemberType Noteproperty "CPUReady%" -value "$cpuready`%"
$capacity | Add-Member -MemberType Noteproperty "Top10%CPUReady" -value "$cpurdytop10ave`%"
$capacity | Add-Member -MemberType Noteproperty "vRAMRatio" -value "$vRAMRatio`:1"
$capacity | Add-Member -MemberType Noteproperty "pRAM \TB" -value ([math]::round($pRAM / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "vRAM \TB" -value ([math]::round($vRAM / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "vRAM Cap \TB" -value ([math]::round($vRAMCap / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "vRAM Remaining \TB" -value ([math]::round($vRAMRemaining / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "Provisioned Space \TB" -value ([math]::round($ProvSpace / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "Physical Capacity \TB" -value ([math]::round($PhysCap / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "Used Space \TB" -value ([math]::round($UsedSpace / 1024,3)) #Change the 3 to a 2 for GB
$capacity | Add-Member -MemberType Noteproperty "Free Space \TB" -value ([math]::round($FreeSpace / 1024,3)) 
$capacity | Add-Member -MemberType Noteproperty "Provisioned %" -value "$ProvPercent`%"
$captable += $capacity
}
#$output += $captable | Convertto-CSV -NoTypeInformation

$output | Set-Content $outfile
#start excel $outfile

Write-Host " Starting Performance Tables" -ForegroundColor Yellow
Section -Style Heading2 " -Cluster Capacity Report for $VC" { 
                Paragraph "This section provides information on the capacity of each Cluster in $vc."
                $captable | Table -List -ColumnWidths 25, 75
                Blankline}
                PageBreak; 
                
Write-Host "Gathering vHost Stats" -ForegroundColor Yellow
Section -Style Heading2 " -vHost Usage stats" { 
                Paragraph "This section provides usage stats on the vHost in $vc over the last 7 days."                  
Get-VMHost | Where {$_.PowerState -eq "PoweredOn"} | Select Name,CpuTotalMhz,MemoryTotalGB, `
@{N="CPU Usage (Average) Mhz" ; E={[Math]::Round((($_ | Get-Stat -Stat cpu.usagemhz.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}}, `
@{N="Memory Usage (Average) %" ; E={[Math]::Round((($_ | Get-Stat -Stat mem.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} , `
@{N="Network Usage (Average) KBps" ; E={[Math]::Round((($_ | Get-Stat -Stat net.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} , `
@{N="Disk Usage (Average) KBps" ; E={[Math]::Round((($_ | Get-Stat -Stat disk.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} |`
Table
Blankline} 
PageBreak;

#Get vHost Uptime info
 function Get-VMHostUptime
    {
        [CmdletBinding()] 
            Param (
                [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)][Alias('Name')][string]$VMHosts,
                [string]$Cluster
                  )
    Process{
         If ($VMHosts) {
            foreach ($VMHost in $VMHosts) {Get-View  -ViewType hostsystem -Property name,runtime.boottime -Filter @{"name" = "$VMHost"} | Select-Object Name, @{N="UptimeDays"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays),0)}}, @{N="UptimeHours"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours),0)}}, @{N="UptimeMinutes"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes),0)}}}
            }
 
         elseif ($Cluster) {
            foreach ($VMHost in (Get-VMHost -Location $Cluster)) {Get-View  -ViewType hostsystem -Property name,runtime.boottime -Filter @{"name" = "$VMHost"} | Select-Object Name, @{N="UptimeDays"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays),0)}}, @{N="UptimeHours"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours),0)}}, @{N="UptimeMinutes"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes),0)}}}
            }
 
         else {
            Get-View  -ViewType hostsystem -Property name,runtime.boottime | Select-Object Name, @{N="UptimeDays"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalDays),0)}}, @{N="UptimeHours"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalHours),0)}}, @{N="UptimeMinutes"; E={[math]::round((((Get-Date) - ($_.Runtime.BootTime)).TotalMinutes),0)}}
            }
        }
        }

#Get vHost Uptime
Write-host "Gathering vHost Uptime Information" -ForegroundColor Yellow
Section -Style Heading2 " -vHost Uptime" { 
                Paragraph "This section provides information on vHost Uptime." 
Get-VMHostUptime $vmhost | select name, uptimedays | Table
BlankLine}


#Gather vHost Active Alerms
Write-host "Gathering Active vHost Alarms" -ForegroundColor Yellow
Section -Style Heading2 " -vHost Active Alerts" { 
                Paragraph "This section provides information on Active vHost Alerts." 
$esx_all = Get-VMHost | Get-View
$Report=@()
foreach ($esx in $esx_all){
    foreach($triggered in $esx.TriggeredAlarmState){
        If ($triggered.OverallStatus -like "red" ){
            $lineitem={} | Select Name, AlarmInfo
            $alarmDef = Get-View -Id $triggered.Alarm
            $lineitem.Name = $esx.Name
            $lineitem.AlarmInfo = $alarmDef.Info.Name
            $Report+=$lineitem
        } 
    }
}
$Report |Sort Name | Table
BlankLine}
PageBreak;

#Get Datastore Information
Write-Host "Gathering Datastore info" -ForegroundColor Yellow
Section -Style Heading2 " -Datastore Information" { 
                Paragraph "This section provides usage stats for all Datastores." 
Get-Datastore |select name, state, id, @{N="Type";E={$_.Type}}, @{N="Version";E={$_.FileSystemVersion}}, @{N="Number of Host";E={$_.ExtensionData.Host.Count}}, @{N="Number of VMs";E={$_.ExtensionData.VM.Count}}, CapacityGB, FreeSpaceGB, @{N="% Used";E={[math]::Round((100 - (($_.FreeSpaceGB) / ($_.CapacityGB) * 100)), 2)}}, StorageIOControlEnabled | Table 
BlankLine}
PageBreak;

#Get LUN info
Write-Host "Gather LUN info" -ForegroundColor Yellow
Section -Style Heading2 " -LUN Information" { 
                Paragraph "This section provides information on all connected LUNS."  
 Get-VMHost | Get-ScsiLun | Sort-Object VMhost | Select-Object VMHost, CanonicalName, CapacityGB, Vendor, MultipathPolicy, LunType, IsLocal, IsSsd | Table
 BlankLine}
 PageBreak;
   
#Get VM Stats
Write-Host "Gathering VM Stats" -ForegroundColor Yellow
Section -Style Heading2 " -VM Usage Stats" { 
                Paragraph "This section provides usage stats for all VM's in $vc over the last 7 days."                  
Get-VM | Where {$_.PowerState -eq "PoweredOn"} | Select Name, VMHost, NumCpu, MemoryMB, `
@{N="CPU Usage (Average) Mhz" ; E={[Math]::Round((($_ | Get-Stat -Stat cpu.usagemhz.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}}, `
@{N="Memory Usage (Average) %" ; E={[Math]::Round((($_ | Get-Stat -Stat mem.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} , `
@{N="Network Usage (Average) KBps" ; E={[Math]::Round((($_ | Get-Stat -Stat net.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} , `
@{N="Disk Usage (Average) KBps" ; E={[Math]::Round((($_ | Get-Stat -Stat disk.usage.average -Start (Get-Date).AddDays(-7) -IntervalMins 5 | Measure-Object Value -Average).Average),2)}} |`
Table
Blankline}
PageBreak;

#Get VM uptime info
Write-host "Gathering VM Uptime Information" -ForegroundColor Yellow
Section -Style Heading2 " -VM Uptime" { 
                Paragraph "This section provides information on VM Uptime." 
$VMs = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
$Output = ForEach ($VM in $VMs)

    { 
    "" | Select @{N="Name";E={$VM.Name}},
    @{N="Powered On";E={$Event = Get-VM $VM.Name | Get-VIEvent -MaxSamples [int]::MaxValue | Where-Object {$_.FullFormattedMessage -like "*powered on*"} | Select-First 1 
    $Event.CreatedTime}},
    @{N="Up Time";E={$Timespan = New-Timespan -Seconds (Get-Stat -Entity $VM.Name -Stat sys.uptime.latest -Realtime -MaxSamples 1).Value
    "" + $Timespan.Days + " Days, "+ $Timespan.Hours + " Hours, " +$Timespan.Minutes + " Minutes"}}
    } 
Write-host "Gathering VM Uptime information" -ForegroundColor Yellow  
$Output | Table
BlankLine}
PageBreak;

#SnapShot data over 5 days old
Write-Host "Gathering Snapshot Data over 5 days old" -ForegroundColor Yellow
Section -Style Heading2 " -SnapShots Over 5 Days Old" { 
                Paragraph "This section provides information on Snapshots over 3 days old." 
Get-VM | Get-Snapshot | Where {$_.Created -Lt (Get-Date).AddDays(-3)} |Select-Object vm, name, created, PowerState, SizeGB | Table
Blankline} 

   #Gather VM Active Alerts
Write-host "Gathering Active VM Alarms" -ForegroundColor Yellow
Section -Style Heading2 " -VM Active Alerts" { 
                Paragraph "This section provides information on Active VM Alerts." 
$VMs = Get-View -ViewType VirtualMachine -Property Name,OverallStatus,TriggeredAlarmstate
$FaultyVMs = $VMs | Where-Object {$_.OverallStatus -ne "Green"}
 
$progress = 1
$report = @()
if ($FaultyVMs -ne $null) {
    foreach ($FaultyVM in $FaultyVMs) {
            foreach ($TriggeredAlarm in $FaultyVM.TriggeredAlarmstate) {
                Write-Progress -Activity "Gathering alarms" -Status "Working on $($FaultyVM.Name)" -PercentComplete ($progress/$FaultyVMs.count*100) -Id 1 -ErrorAction SilentlyContinue
                $alarmID = $TriggeredAlarm.Alarm.ToString()
                $object = New-Object PSObject
                Add-Member -InputObject $object NoteProperty VM $FaultyVM.Name
                Add-Member -InputObject $object NoteProperty TriggeredAlarms ("$(Get-AlarmDefinition -Id $alarmID)")
                $report += $object
            }
        $progress++
        }
    }
Write-Progress -Activity "Gathering Active VM alarms" -Status "All done" -Completed -Id 1 -ErrorAction SilentlyContinue
 
$report | Where-Object {$_.TriggeredAlarms -ne ""} |Table
Blankline}


}
    
$document | Export-Document -Path ~\Desktop -Format Word,Html -PassThru:$PassThru -Verbose;
$synthesizer.SelectVoice('Microsoft David Desktop')
$synthesizer.Speak('Documentation Complete. Word and HTML files are located on your desktop')


Disconnect-viserver -Server * -Confirm:$false

}
Function Set-RR {
#Setting Storage Luns to Round Robin

$VC = Read-Host " Enter vCenter name:"


Connect-VIServer $VC

Get-Cluster | Select name | FT
$Cluster = Read-Host " Enter Cluster name fron list above:"


$VMhosts = Get-cluster $cluster | Get-VMHost

Foreach ($VMhost in $VMhosts) {
        Write-Host "Setting Multipath Policy on $VMhost to Round Robin" -ForegroundColor Green
        Get-VMHost $VMhost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -notlike "RoundRobin"} | Set-Scsilun -MultiPathPolicy RoundRobin
        Get-VMhost $VMhost | Get-ScsiLun -LunType Disk | Where-Object {$_.CanonicalName -like ‘naa.*’ -and $_.MultipathPolicy -like ‘RoundRobin’} | Set-ScsiLun -CommandsToSwitchPath 1

        }


Write-host "disconnecting from $VC" -ForegroundColor Yellow
Disconnect-VIServer -Server * -Confirm:$False

}
Function Change-CPU {
$VC = Read-Host "Enter the vCenter name or IP"
Connect-VIServer $VC

CLS

$VM = Read-Host "Enter the name of the VM to change the vCPU of"
$NumCPU = Read-Host "Enter the total number of vCPU $VM needs to have" 

Write-Host "Shutting Down $VM to make change" -ForegroundColor Yellow
Get-VM $VM | Shutdown-VMGuest -Confirm:$false
sleep 60
Set-VM -VM $VM -NumCpu $NumCPU -Confirm:$false
sleep 5
Start-VM $VM

Write-Host "Change complete, $VM is powering on" -ForegroundColor Yellow

Disconnect-VIServer -Server * -Confirm:$false

}
Function Change-Memory {
$VC = Read-Host "Enter the vCenter name or IP"
Connect-VIServer $VC

CLS

$VM = Read-Host "Enter the name of the VM to change the Memory on"
$NumMEM = Read-Host "Enter the total amount of Memory $VM needs to have in GB" 

Write-Host "Shutting Down $VM to make change" -ForegroundColor Yellow
Get-VM $VM | Shutdown-VMGuest -Confirm:$false
sleep 60
Set-VM $VM -MemoryGB $NumMem -Confirm:$false
sleep 5
Start-VM $VM

Write-Host "Change complete, $VM is powering on" -ForegroundColor Yellow

Disconnect-VIServer -Server * -Confirm:$false

}

 
do
{
    Show-Menu –Title 'Select Script'
    $input = Read-Host "what do you want to do?"
    switch ($input)
    {
        '1' {               
                Get-VDCEdge
            }
        '2' {
                New-Tenant
            }
        '3' {
                Get-VMinfo
            }
        '4' {
                Get-Capacity
            }
        '5' {
                Set-RR
            }
        '6' {
                Change-CPU
            }
        '7' {
                Change-Memory
            }
        'q' {
                 return
            }
    }
    pause
}
until ($input -eq 'q')

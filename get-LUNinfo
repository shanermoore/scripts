
$VC = read-host "Enter vCenter name or IP address"

Connect-Viserver $VC

Write-Host "Gather LUN info" -ForegroundColor Yellow
 # Get VMFS volumes. Ignore local SCSILuns. 
 Get-VMHost | Get-ScsiLun | Sort-Object VMhost | Select-Object VMHost, CanonicalName, CapacityGB, Vendor, MultipathPolicy, LunType, IsLocal, IsSsd, @{n='LunID';E={

        $esxcli = Get-EsxCli -VMHost $_.VMHost -V2

        $esxcli.storage.nmp.path.list.Invoke(@{'device'=$_.CanonicalName}).RuntimeName.Split(':')[-1].TrimStart('L')}} | 
Sort-Object -Property {[int]$_.LUN} | Export-Csv C:\Temp\Luns.csv -NoTypeInformation

Disconnect-viserver -server * -confirm:$false

#Enter the vCenter or ESXi name or ip
$vc = Read-Host "Enter vCenter or ESXi name or IP address"
Connect-VIServer $vc

#Add VM properties for vmtools version
Write-Host "Adding VM Properties for vmtools" -ForegroundColor Yellow
New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force 
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force

#Get VM info
Write-Host "Gathering VM info" -ForegroundColor Yellow
get-cluster | Get-VM | Select Name, Folder, @{N="IP Address";E={@($_.guest.IPAddress[0])}}, @{N='FQDN';E={$_.ExtensionData.Guest.IPStack[0].DnsConfig.HostName, $_.ExtensionData.Guest.IPStack[0].DnsConfig.DomainName -join '.'}}, Guest, Version, ToolsVersion, ToolsVersionStatus, PowerState, NumCpu, MemoryGB, ProvisionedSpaceGB, UsedSpaceGB | Export-Csv C:\Temp\VMinfo.csv -NoTypeInformation 

Write-host "Spreadsheet is located at C:\temp\VMinfo.csv" -ForegroundColor Green

Disconnect-viserver -server * -confirm:$false

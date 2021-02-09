$VC = Read-Host "Enter vCenter Name/IP"
Connect-Viserver $VC


#Gather VM Active Alerts
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
 
$report | Where-Object {$_.TriggeredAlarms -ne ""} |Export-Csv C:\Temp\vmAlert.csv -NoTypeInformation

#Gather vHost Active Alerms
Write-host "Gathering Active vHost Alarms" -ForegroundColor Yellow
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
$Report |Sort Name | Export-Csv C:\Temp\HostAlarms.csv -NoTypeInformation

Disconnect-viserver -Server * -Confirm:$false

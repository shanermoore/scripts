#Get vCenter name and Connect
Write-host ""
$vc = Read-Host "Enter vCenter name to conenct to"
Write-Host ""
Write-host "Connecting to $vc, Login prompt to follow.." -ForegroundColor Cyan
Connect-VIServer $vc

#Get list of all clusters in vCenter
$Clusters = Get-Cluster
ForEach ($c in $Clusters){
    Write-host "Processing Cluster $c..." -ForegroundColor Magenta
    Write-host ""  
        
        #Process each host in cluster
        $NUMAStats = @()
        $largeMemVM = @()
        $largeCPUVM = @()

        $hosts = Get-VMHost -Location $c    

            ForEach ($h in $Hosts) {
                    $HostView = $h | Get-View
                    $HostSummary = “” | Select HostName, MemorySizeGB, CPUSockets, CPUCoresSocket, CPUCoresTotal, CPUThreads, NumNUMANodes, NUMANodeCPUSize, NUMANodeMemSize

                        #Get Host CPU, Memory & NUMA info
                        $HostSummary.HostName = $h.Name
                        $HostSummary.MemorySizeGB =([Math]::Round($HostView.hardware.memorysize / 1GB))
                        $HostSummary.CPUSockets = $HostView.hardware.cpuinfo.numCpuPackages
                        $HostSummary.CPUCoresSocket = ($HostView.hardware.cpuinfo.numCpuCores / $HostSummary.CPUSockets)
                        $HostSummary.CPUCoresTotal = $HostView.hardware.cpuinfo.numCpuCores
                        $HostSummary.CPUThreads = $HostView.hardware.cpuinfo.numCpuThreads
                        $HostSummary.NumNUMANodes = $HostView.hardware.numainfo.NumNodes
                        $HostSummary.NUMANodeCPUSize = ($HostSummary.CPUCoresTotal / $HostSummary.NumNUMANodes)
                        $HostSummary.NUMANodeMemSize =([Math]::Round($HostSummary.MemorySizeGB / $HostSummary.NumNUMANodes))
                        $NUMAStats += $HostSummary
            }

                #Find the smallest NUMA Node (CPU & Mem) to use for comparison
                $x =  $HostSummary.NUMANodeMemSize | measure -Minimum
                $y =  $HostSummary.NUMANodeCPuSize | measure -Minimum

                #Get list of all VMs in cluster that are oversized
                $VMDeatils = @()
                $VMDeatils = Get-VM -Location $c | where {$_.NumCpu -gt $y.Minimum -or $_.MemoryGB -gt $y.Minimum}

                Write-host "Processing VM's in cluster for NUMA oversizing.." -ForegroundColor Magenta
                Write-host ""
               
                # VM Calculations
                #Large MEM VM - Any VM with more memory allocated then the NUMA node.
                $largeMemVM += $VMDeatils | Where-Object {$_.MemoryGB -gt $x.Minimum}

                #Large CPU VM - Any VM with more CPU then cores per Proc on a host
                $largeCPUVM += $VMDeatils | Where-Object {$_.NumCPU -gt $y.Minimum}
        
                #Display report for current cluster                
                        Write-Host "NUMA Node Specs for Cluster - $c." -ForegroundColor Yellow
                        $NUMAStats | ft

            if ($largeMemVM -or $largeCPUVM) {
                    if ($largeCPUVM) {
                        Write-host $largeCPUVM.Count "VMs in $c that Exceed CPUCoresSocket." -ForegroundColor Cyan
                        $largeCPUVM | select name, @{N='Memory GB';E={$_.MemoryGB}}, @{N='Num CPU';E={$_.ExtensionData.Config.Hardware.NumCPU}}, @{N='Num Sockets';E={($_.ExtensionData.Config.Hardware.NumCPU / $_.ExtensionData.Config.Hardware.NumCoresPerSocket)}}, @{N='Cores Per Socket';E={$_.ExtensionData.Config.Hardware.NumCoresPerSocket}}, @{N='CPU Hot Plug Status';E={$_.ExtensionData.Config.CpuHotAddEnabled}} | ft
                    }
                    Else { Write-host "All VM CPU allocations are within NUMA ranges" -ForegroundColor Green}

                    if ($largeMemVM) {
                        Write-host $largeMemVM.Count "VMs in $c that Exceed NUMA Node Memory size." -ForegroundColor Cyan
                        $largeMemVM | select name, @{N='Memory GB';E={$_.MemoryGB}}, @{N='Num CPU';E={$_.ExtensionData.Config.Hardware.NumCPU}}, @{N='Num Sockets';E={($_.ExtensionData.Config.Hardware.NumCPU / $_.ExtensionData.Config.Hardware.NumCoresPerSocket)}}, @{N='Cores Per Socket';E={$_.ExtensionData.Config.Hardware.NumCoresPerSocket}}, @{N='CPU Hot Plug Status';E={$_.ExtensionData.Config.CpuHotAddEnabled}} | ft
                    }
                    Else { Write-host "All VM memory allocations are within NUMA ranges" -ForegroundColor Green}
                }
            Else { Write-Host "No VM's in Cluster - $c to report NUMA issues on" -ForegroundColor Green}
            Write-host ""
            Write-host ""
}
Write-Host "Disconnecting from $vc" -ForegroundColor Yellow
Disconnect-viserver -Server $vc -Confirm:$false

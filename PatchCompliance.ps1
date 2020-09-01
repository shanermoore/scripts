$WSUS = Read-Host "Enter Name/IP of WSUS server"
$VC = Read-Host "Enter vCenter Name/IP"
$reportname = Read-Host "Enter Report Name"
$CompanyName = Read-Host "Enter Company Name "
$author = Read-Host "Enter Author Name"


Connect-PSWSUSServer $WSUS -Port 8530
Connect-VIServer $VC
 



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
                'Author:'  = $author
                'Date:'    = Get-Date -Format 'dd MMMM yyyy'
                'Version:' = Get-date -Format 'yyyyMM'
                })

    PageBreak;

    # Table of Contents
    TOC -Name 'Table of Contents'
    PageBreak;
Section -Style Heading1 ". Windows Server Patch Compliance" { 
                Paragraph "This Section shows the patch compliance of the Windows servers in the Edafio Cloud Management Cluster"
                 Get-PSWSUSUpdateSummaryPerClient |Select Computer, Installed, Needed, Failed, PendingReboot, NotApplicable, LastUpdated | Sort-Object Computer| Table
                Blankline}
                PageBreak;
                
 Section -Style Heading1 ". VMware Host Patch Compliance" { 
                Paragraph "This Section shows the patch compliance of the VMware Host in the Edafio Cloud " 
$clusters = Get-Cluster
$BL = Get-Baseline -Name "HP Host" -BaselineType Patch

Foreach ($Cluster in $Clusters) {
Section -Style Heading3 " $cluster Cluster Compliance" { 
                 
Write-host "Compliance for $cluster Cluster" -ForegroundColor Yellow
Test-Compliance -Entity $cluster -UpdateType HostPatch
Get-Compliance -Entity $cluster -Baseline $BL -Detailed | Select-object Entity, @{N=’Baseline’;E={$_.Baseline.Name}}, Status, @{N=’CompliantPatches’;E={$_.CompliantPatches.Length}}, @{N=’NotCompliantPatches’;E={$_.NotCompliantPatches.Length}},@{N=’UnknownPatches’;E={$_.UnknownPatches.Length}}, @{N=’NotApplicablePatches’;E={$_.NotApplicablePatches.Length}} |  Table
Blankline}
PageBreak;
}
}
Section -Style Heading1 ". Missing VMware Host Patches" { 
                Paragraph "This Section shows what patches are missing from the VMware Host in the Edafio Cloud " 
                $esx = Get-VMHost |Get-Random

Test-Compliance -Entity $esx -UpdateType HostPatch

$report = $esx | Get-Compliance -Detailed | %{

    $_.NotCompliantPatches |

    Select-Object Name,IDByVendor,Description,@{n='Product';e={$_.product | Select-Object -expandproperty Version}},ReleaseDate

}

 

$report |Table
  BlankLine}
  PageBreak;
}
$document | Export-Document -Path ~\Desktop -Format Word,Html -PassThru:$PassThru -Verbose;

Disconnect-PSWSUSServer
Disconnect-VIServer -Server * -Confirm:$False


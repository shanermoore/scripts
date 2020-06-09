param ([System.Management.Automation.SwitchParameter] $PassThru)


Import-Module PScribo -Force;

$ReportName = "Virtual Machine Inventory Report"
$CompanyName = Read-Host "Enter Company Name"
$Author = Read-Host "Enter Author Name"
$Version = Read-Host "Enter Version Number"
$vc = Read-Host "Enter vCenter Name/IP"
#$creds = Get-Credential
$name = "$CompanyName $ReportName"

<# The document name is used in the file output #>
$document = Document $name -Verbose {
    <#  Enforce uppercase section headers/names
        Enable automatic section numbering
        Set the page size to US Letter with 0.5inch margins #>
    $DefaultFont = 'Calibri'

    #region VMware Document Style
    DocumentOption -EnableSectionNumbering -PageSize Letter -DefaultFont $DefaultFont -MarginLeftAndRight 71 -MarginTopAndBottom 71

    Style -Name 'Title' -Size 24 -Color '002538' -Align Center
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
    BlankLine -Count 5
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

    Connect-VIServer $vc 
    Section -Style Heading2 'Virtual Machine' {
    #Add VM properties for vmtools version
Write-Host "Adding VM Properties for vmtools" -ForegroundColor Yellow
New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force 
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force

#Get VM info
Write-Host "Gathering VM info" -ForegroundColor Yellow
$VMS = get-cluster | Get-VM | Select Name, Folder, @{N="IP Address";E={@($_.guest.IPAddress[0])}}, @{N='FQDN';E={$_.ExtensionData.Guest.IPStack[0].DnsConfig.HostName, $_.ExtensionData.Guest.IPStack[0].DnsConfig.DomainName -join '.'}}, Guest, Version, ToolsVersion, ToolsVersionStatus, PowerState, NumCpu, MemoryGB, ProvisionedSpaceGB, UsedSpaceGB  | Sort-Object Folder

$VMS |Table -List -Name 'Virtual Machines' -ColumnWidths 25,75

}

    }
    $document | Export-Document -Path ~\Desktop -Format Word,Html -PassThru:$PassThru -Verbose;


    Disconnect-VIServer -Server * -Confirm:$false

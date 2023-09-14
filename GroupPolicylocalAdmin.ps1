<#
Script Info

Author: Andreas Lucas [MSFT]
Download: 

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages
#>
<#
.Synopsis
    The script creates report about any group available group policies and searches in the report for users / groups added to the local administrator group
    by group policies preferences     
.DESCRIPTION
    This script searches for group polices, where users / groups added tot local Administrator group by group policy preferences 
    This script required the group policy module
.EXAMPLE
    .\grouppolicylocaladmin.ps1
    create a CSV report (GpoWithLocalAdmins.csv) in the current directory
     .\grouppolicylocaladmin.ps1 -csv <filename>
    create a CSV report <filename>
     

.INPUTS
    -csv is the report file
.OUTPUTS
   CSV file with the name of the group policy and the name of the user to add 
.NOTES
    
    Version Tracking
    0.1.20230901
        - First internal release
    0.1.20230905
        - show the current nummer ob the computer
    0.1.20230907
        - show the CSV file path 
        - addtional output
    0.1.20230911
        - Now is looks for remote users which indirect get the "allow-to-authenticate" due group nesting
#>
Param(
    # output csv filename 
    [Parameter(Mandatory = $false)]
    [string]$csv=".\GpoWithLocalAdmins.csv"
)
$scriptVersion = "0.1.20230914.1326"

Write-Host "Enumeratiing local Administrators applied by Group polices (Script Version $scriptVersion)"

Import-Module GroupPolicy
#import the GroupPolicy module and check it is available
if (Get-Module GroupPolicy){
    $Report = @()
    Foreach ($Gpo in Get-GPO -all){ 
        #searching for any group policy where the computer settings are enabled
    if (($Gpo.GpoStatus -eq "AllSettingsEnabled") -or ($Gpo.GpoStatus -eq "UserSettingsDisabled")){
            Write-Progress -Activity "Analyzing group policy" -CurrentOperation "$($Gpo.DisplayName)"
            #creating the report to analysis the preferences 
            [System.Xml.XmlDocument]$xmlReport = Get-GPOReport -Guid $Gpo.Id -ReportType Xml
            Foreach ($xmlExtension in $xmlReport.GPO.Computer.ExtensionData){
                if ($xmlExtension.Name -eq "Local Users and Groups"){
                    foreach ($xmlGroup in $xmlExtension.FirstChild.LocalUsersAndGroups.Group){
                        if ($xmlGroup.name -eq "Administrators (built-in)"){
                            if ($xmlGroup.Properties.action -eq "U"){
                                Foreach ($member in $xmlGroup.Properties.Members.Member){
                                    $GroupPolicy = New-Object PSObject
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "GroupPolicyName" -Value $Gpo.DisplayName
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LocalAdministrators" -Value $member.Name
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "SID" -Value $xmlReport.GPO.LinksTo.InnerXml
#                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LinkedTo" -Value $Gpo.
                                    $Report += $GroupPolicy
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Analyzing group policy" -Completed
    Write-Host "creating report file $csv" -ForegroundColor Green
    $Report | Export-Csv $csv
} else {
    #if the Group Policy module is not available report a error
    Write-Host "This script requires the GroupPolicy Module" -ForegroundColor Red
}
<#
Script Info

Author: Andreas Lucas [MSFT]
Download: https://github.com/Kili69/LocalAdminsByGPOReport

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
.PARAMETER csv
    Is the name of the output file
.PARAMETER Domain
    Is the FQDN of the AD domain who should be analyzed. If this parameter is not available the current user domain will be used     

.INPUTS
    -csv is the report file
.OUTPUTS
   CSV file with the name of the group policy and the name of the user to add 
.NOTES
    
    Version Tracking
    0.1.20230919
        - First internal release
    0.1.20240114
        - new parameter -Domain to analyze child domains
#>
Param(
    # output csv filename 
    [Parameter(Mandatory = $false)]
    [string]$csv=".\GpoWithLocalAdmins.csv",
    [Parameter(Mandatory = $false)]
    [string]$Domain
)
$scriptVersion = "0.1.20240114"
if ($Domain -ne ""){
    $csv = ".\$Domain-GpoWithLocalAdmins.csv"
} else {
    $Domain = (Get-ADDomain).DNSRoot
}

Write-Host "Enumeratiing local Administrators applied by Group polices (Script Version $scriptVersion)"
New-Item -Path $csv -ItemType File -Force

Import-Module GroupPolicy
#import the GroupPolicy module and check it is available
if (Get-Module GroupPolicy){
    Foreach ($Gpo in Get-GPO -all -Domain $Domain){ 
    #searching for any group policy where the computer settings are enabled
    if (($Gpo.GpoStatus -eq "AllSettingsEnabled") -or ($Gpo.GpoStatus -eq "UserSettingsDisabled")){
        Write-Progress -Activity "Analyzing group policy" -CurrentOperation "$($Gpo.DisplayName)"
        #creating the report to analysis the preferences 
        [System.Xml.XmlDocument]$xmlReport = Get-GPOReport -Guid $Gpo.Id -ReportType Xml -Domain $Domain
        Foreach ($xmlExtension in $xmlReport.GPO.Computer.ExtensionData){
            switch ($xmlExtension.Name){
                "Local Users and Groups" {
                    foreach ($xmlGroup in $xmlExtension.FirstChild.LocalUsersAndGroups.Group){
                        if ($xmlGroup.name -eq "Administrators (built-in)"){
                            if ($xmlGroup.Properties.action -eq "U"){
                                Foreach ($member in $xmlGroup.Properties.Members.Member){
                                    $GroupPolicy = New-Object PSObject
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "GroupPolicyName" -Value $Gpo.DisplayName
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LocalAdministrators" -Value $member.Name
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "Method" -Value "Group Policy preferences"
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "SID" -Value $member.SID
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LinkTo" -Value $xmlReport.GPO.LinksTo.InnerXml
                                    #$Report += $GroupPolicy
                                    export-csv -InputObject $GroupPolicy -Append -NoTypeInformation -Path $csv 
                                }
                            }
                        }
                    }    
                }
                    "Security"{
                        Foreach ($RestrictedGroup in $xmlExtension.FirstChild.RestrictedGroups){
                            if($RestrictedGroup.GroupName.SID.InnerText -like "*-544"){
                                Foreach ($xmlMember in $RestrictedGroup.Member){
                                    $GroupPolicy = New-Object PSObject
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "GroupPolicyName" -Value $Gpo.DisplayName
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LocalAdministrators" -Value $xmlMember.Name.InnerText
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "Method" -Value "Restricted Groups"
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "SID" -Value $xmlMember.SID.InnerText
                                    $GroupPolicy | Add-Member -MemberType NoteProperty -Name "LinkTo" -Value $xmlReport.GPO.LinksTo.InnerXml
                                    #$Report += $GroupPolicy
                                    export-csv -InputObject $GroupPolicy -Append -NoTypeInformation -Path $csv 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Analyzing group policy" -Completed
    #Write-Host "creating report file $csv" -ForegroundColor Green
    #$Report | Export-Csv $csv
} else {
    #if the Group Policy module is not available report a error
    Write-Host "This script requires the GroupPolicy Module" -ForegroundColor Red
}
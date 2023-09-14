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
Import-Module GroupPolicy
if (Get-Module GroupPolicy){
    $Report = @()
    Foreach ($Gpo in Get-GPO -all){
        if (($Gpo.GpoStatus -eq "AllSettingsEnabled") -or ($Gpo.GpoStatus -eq "UserSettingsDisabled")){
            Write-Host $Gpo.DisplayName
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
                                    $Report += $GroupPolicy
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    $Report | Export-Csv .\GpoWithLocalAdmins.csv
} else {
    Write-Host "This script requires the GroupPolicy Module"
}
# LocalAdminsByGPOReport
## Description 
Active Directory group policies are a powerful tool for managing the configuration and security of computers and users in a domain. However, sometimes it can be difficult to keep track of which groups or users have been added to the local administrator group on each computer, which can pose a security risk or cause conflicts. This script will analyze any available group policy in the Active Directory and reports which user/group will be added to the local administrators groups be Group Policy Restricted Groups or Group Policy Preferences.

## Prerequisites
This script uses the Active Directory Powershell module and the Group Policy module. The script does requires only to read group polices. Domain Admin privileges only required 

## Usage
The script could run without any parameter. In this case the script will analyze the current users Active Directory domain and store the result in the file GpoWithLocalAdmins.csv. 
Addtional paramters are available:
### -CSV
Is the name of the output file
### -Domain
To analyze child or tree domain in a multi-domain active directory forest use the paramter -domain followed by the domain name

## Example
### GroupPolicylocalAdmins.ps1 
Analyze all group policies in the local active directory
### GroupPolicylocalAdmins.ps1 -csv .\mydomain.csv
Analyze all group policies in the local active directory and store the result in the file mydomain.csv
### GroupPolicylocalAdmins.ps1 -domain child.contoso.com
Analyze all group policies in the child.contoso.com domain and store the result in child.contoso.com-GpoWithLocalAdmins.csv

# Version 
## Version 0.1.20230919
Initial Version
## Version 0.1.20240114
New parameter -domain added to analyze child domains 


# Disclaimer
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages


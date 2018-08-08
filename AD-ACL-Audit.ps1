<#	
	.NOTES
	==========================================================================
	 Created on:   	14/02/2018 11:51
	 Created by:   	Joe Dibley
	 Filename:     	AD ACL Report
	===========================================================================
	.DESCRIPTION
		Export all information required for the AD ACL Scan for importing into
		a database for querying to find dodgy and unknown access rules rules that 
		may exist in your Active Directory Environment.
    
  .PARAMETER ExportDirectory
   A directory to export the ACL Files to
   
  .PARAMETER Domain
    The name of the domain that is being scanned
    
#>
param (
		[Parameter()]
    [ValidateScript({
				if (-Not ($_ | Test-Path))
				{
					throw "File or folder does not exist"
				}
				return $true
			})]
		[System.IO.FileInfo]$ExportDirectory,
    [Parameter()]
    [String]$Domain,
    [Parameter()]
    [Switch]$IncludeInherited
)

#Requires -Module ActiveDirectory


#Variables that need manually settings
#A directory to export files to.
$ExportDirectory = ""

#Update for whatever domain you want to run this against.
$Domain = ""

#File names for each file that can be exported
$RightsGUIDFile = "$ExportDirectory\RightsGUID.csv"
$SchemaGUIDFile = "$ExportDirectory\SchemaGUIDs.csv"
$DirectACLFile = "$ExportDirectory\DirectACLs.csv"
$AllACLFile = "$ExportDirectory\AllACLs.csv"
$Errors = "$ExportDirectory\Errors.log"


#Getting the ADRootDSE
$rootdse = Get-ADRootDSE
#Getting Rights GUIDS to be used for transforming ACL's into readable formats
$RightsGUIDS = Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid
#Getting Schema GUIDs ot be used for transforming ACLs into readable formats
$SchemaGUIDS = Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID

#Exporting Rights and Schema GUIDS files
$RightsGUIDS | Export-Csv $RightsGUIDFile -NoTypeInformation
#SchemaGUID requires some transformation to change the SchemaIDGUID from hex to GUID.
$SchemaGUIDS | Select-Object *, @{ Name = "SchemaGUID"; Expression = { [System.Guid]$_.SchemaIDGUID | Select-Object -expand GUID } } | Export-Csv $SchemaGUIDFile -NoTypeInformation

#Create Active Directory Providor Drive
New-PSDrive -PSProvider ActiveDirectory -Name GC -Root ""

#change to ActiveDirectory PSDrive
Set-Location -Path GC:

#Get all objects from $Domain
$AllObjects = Get-ADObject -Filter "*" -Server $Domain -Properties * | Sort-Object CanonicalName

#Starting loop through objects to get rules and output to $DirectACLFile
$AllObjects | ForEach-Object{
	#Getting ACL
	$DN = $_.DistinguishedName
	$CanonicalName = $_.CanonicalName
	$Name = $_.Name
	
	$CanonicalName
	
	#getting ACL
	$ACL = Get-Acl $_.DistinguishedName
	
	#Getting ACL owner and primary group
	$ACLOwner = $ACL.Owner
	$ACLGroup = $ACL.Group
	
	#Getting the ACL access rules
	$ACLAccessRules = $ACL.Access
	
	#Filtering the ACL access rules to only direct access rules and then performing a custom select
	$DirectACLAccessRules = $ACLAccessRules | where { $_.IsInherited -eq $false } | Select-Object @{ Name = "ObjectName"; Expression = { $Name } }, @{ Name = "CanonicalName"; Expression = { $CanonicalName } }, @{ Name = "DistinguishedName"; Expression = { $DistinguishedName } }, @{ Name = "Owner"; Expression = { $ACLOwner } }, @{ Name = "Group"; Expression = { $ACLGroup } }, *
	
	#appending the ACL Rules to the CSV file
	$DirectACLAccessRules | Export-Csv $DirectACLFile -Append -NoTypeInformation
	
  if ( $IncludeInherited ){
	  #This gets all ACL's including inherited ACL's. If this is required then uncomment. 
	  #Normally only direct ACL's are needed but this one could help find things proagrating that you are unaware of.
	
	  $AllACLAccessRules = $ACLAccessRules | Select-Object @{ Name = "ObjectName"; Expression = { $Name } }, @{ Name = "CanonicalName"; Expression = { $CanonicalName } }, @{ Name = "DistinguishedName"; Expression = { $DistinguishedName } }, @{ Name = "Owner"; Expression = { $ACLOwner } }, @{ Name = "Group"; Expression = { $ACLGroup } }, *
	  $AllACLAccessRules | Export-Csv $AllACLFile -Append -NoTypeInformation
	}
}


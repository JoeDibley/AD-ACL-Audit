# AD-ACL-Audit
A PowerShell Script and documentation to do a full AD ACL audit of your own or a clients Active Directory.

When I set this up Microsoft Access was used to do the analytics however any database could be used.

## Requirements
PowerShell v3 (For Export-csv -Append)
Active Directory Module
Read Only Access To Active Directory

Following variables in the AD ACL Report Script:
- $Domain             - The Domain that you want to get permissions from
- $ExportDirectory    - A Directory that the user account running has access to to create new files

## What Does It Do?
This process only requires Read Only Active Directory Access and retieves the following and outputs to multiple CSV files from PowerShell:
- All Active Directory Schema Names and GUIDS
- All Active Directory Rights Names, ObjectGUIDS and RightsGUIDs
- All Non-Inherited Permissions for All Active Directory Objects in the specificed domain

## Importing Files Into Access
Import each of the following CSV files into their own tables in a Database:
- SchemaGUIDS
- RightsGUIDS
- DirectACLs
- AllACLs (If uncommenting the AllACLs section at the bottom)

Create a relationship between the following fields

|Table| Field | Relationship Table | Relationship Field |
| --- | --- | --- | --- |
|RightsGUID|rightsguid| DirectACLs| ObjectType|
|SchemaGUIDS|SchemaGUID|DirectACLs|InheritedObjectType



﻿<#
.SYNOPSIS

script for cleaning up user mailbox/journaling mailbox via scheduled task

.DESCRIPTION

this script was written to clean up journaling mailbox via scheduled task. 
You can also use it to clean up every mailbox on your exchange system. Logfiles will be written next to the script


.EXAMPLE
for schedule task use the path to powershell.exe (default C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe) 
As arguments you can use << -NonInteractive -WindowStyle Hidden -command ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; C:\temp\cleanup-mailbox\get-mailbox.ps1 >>


.Notes
special permission are needed for this action see;
Configure your user with the right permissions-> New-ManagementRoleAssignment -Name ImportExportRole -User domain\user -Role 'Mailbox Import Export', also check if the user is member of the Discovery Management/Organization Management Group in AD "
You also need to give the user permission to logon as batch and local adminrights on the computer where you generate the task!


Please define variables 
username
cleanupmailbox

inside scheduled task:
use the same user specified in varialbe username for the schedule task 
set the priviliges to high

  
---------------------------------------------------------------------------------
                                                                                 
 Script:       mailbox-cleanup0-1.ps1                                      
 Author:       A. Koehler; blog.it-koehler.com
ModifyDate:   03/10/2016                                                        
 Usage:        run as scheduled task for cleaning up journaling mailbox
Version:      0.1
                                                                                  
---------------------------------------------------------------------------------
#>


#define username who has the right permissions für deleting files from exchange mailbox (SamAccountName)
$username = "deleteuser"
#define username which should be cleaned up completly (e-mailaddress)
$cleanupmailbox = "Test01@demo01.it-koehler.com"


########## begin the script
$date=((Get-Date).ToString('yyyy-MM-dd-HH-mm-ss'))
#find out date and convert to string
$datelog = ((Get-Date).ToString('dd-MM-yyyy'))
#find out current hour and convert to string
$timelog = ((Get-Date).ToString('HH-mm-ss'))
#define script path for use with scheduled task
$logpath = split-path -parent $MyInvocation.MyCommand.Definition
#'$logpath = (Get-Location).Path' is for the use in ise/powershell only
$logfile = "$logpath\cleanup_"+$date+".log"
#check if ActiveDirectory Module is loaded, if not load it
    $ADModule='ActiveDirectory'
    if (Get-Module -Name $ADModule) {
    }
    else {
        Import-Module $ADModule -force
    }

#function for logging actions performed by the script
Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

Logwrite "#####################################################################"
Logwrite "#      mailbox cleanup by blog.it-koehler.com                       #"
Logwrite "#         started on  $datelog    $timelog                        #"
Logwrite "#            content deleted with user $username                     #"
Logwrite "#                                                                   #"
Logwrite "#####################################################################"


#check if the user has permissions needed discovery management
$checkdiscoverymanagement = Get-ADGroupMember "Discovery Management"
if($checkdiscoverymanagement -eq $null)
{
Logwrite "Permission for user $username is missing! Configure your user with the right permissions check if the user is member of the 'Discovery Management' Group in AD "
exit
}

else{
$checkpermissiondiscgrp = ((Get-ADGroupMember -Identity "Discovery Management").SamAccountName).Contains($username)
Logwrite "Permission for user $username is missing! Configure your user with the right permissions check if the user is member of the 'Discovery Management' Group in AD "
exit
}


#check exchange permission
$name = ((Get-AdUser $username).Name)
$checkpermissionimpexp = (Get-ManagementRoleAssignment -Role "Mailbox Import Export" -RoleAssignee $name)
if( ($checkpermissionimpexp -eq $null) -and ($checkpermissiondiscgrp -eq $false) )
{
   Logwrite "Permission for user $username Import-Export is missing! Configure your user with the right permissions see command: New-ManagementRoleAssignment -Name ImportExportRole -User domain\user -Role 'Mailbox Import Export', also check if the user is member of the Discovery Management Group in AD "
}
else {
#deleting the content of the whole mailbox
$deletestats = (Search-Mailbox -Identity $cleanupmailbox -DeleteContent -force)
$deletesize = (($deletestats).ResultItemsSize)
$deleteitems = (($deletestats).ResultItemsCount) 
}
#check if cleanup was successfull
if( ($deletestats).Success -eq $true )
{
    Logwrite "Cleaning mailbox $cleanupmailbox was successfull. $deleteitems items were deletet and $deletesize were removed!"
}
else {
    Logwrite "Cleaning mailbox $cleanupmailbox was NOT successfull. Please check eventlog containing errors with search-mailbox parameter -DeleteContent"
}
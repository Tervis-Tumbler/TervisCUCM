#Requires -Modules CUCMPowerShell

Function Invoke-TervisCUCMTerminateUser {
    param(
        $UserName
    )

    $CUCMUser = Get-CUCMUser -UserID $UserName
    $DeviceNames = $CUCMUser.associatedDevices.device
    $Phones = foreach ($DeviceName in $DeviceNames) { Get-CUCMPhone -Name $DeviceName }
    $Lines = $Phones.lines.line

    ForEach ($DirectoryNumber in $Lines.dirn ) { 
        $SetCUCMLineResponse = Set-CUCMLine -Pattern $DirectoryNumber.Pattern -RoutePartitionName $DirectoryNumber.routePartitionName."#text" -Description "" -AlertingName "" -AsciiAlertingName "" 
    }

    $RemoveCUCMPhoneResponse = $Phones | Remove-CUCMPhone
}

function Get-CUCMDeviceName {
    param(
        [Parameter(Mandatory)][String]$UserIDAssociatedWithDevice
    )

    $QueryForDevicesByUserID = @"
select device.name, enduser.userid from device, enduser, enduserdevicemap
where device.pkid=enduserdevicemap.fkdevice and  
enduser.pkid=enduserdevicemap.fkenduser and enduser.userid = '$UserIDAssociatedWithDevice'
"@

    Invoke-CUCMSQLQuery -SQL $QueryForDevicesByUserID
}
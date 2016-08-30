#Requires -Modules CUCMPowerShell

function Find-CUCMUserWithoutMatchingTelephoneNumberInAD {
    $CUCMUsers = Find-CUCMUser -firstName "%"
    foreach ($CUCMUserID in $CUCMUsers.userID) {
        $CUCMUser = Get-CUCMUser -UserID $CUCMUserID
        $DeviceNames = $CUCMUser.associatedDevices.device
        if ($DeviceNames) {
            $Phones = foreach ($DeviceName in $DeviceNames) { Get-CUCMPhone -Name $DeviceName }
            $DirectoryNumbers = $Phones.lines.line.dirn.pattern
            if ($DirectoryNumbers) {
                $ADUser = Get-ADUser -Identity $CUCMUserID -properties TelephoneNumber
                if ($ADUser.TelephoneNumber -notin $DirectoryNumbers) {
                    $ADUser 
                }
            }
        }
    }
}

Function Invoke-TervisCUCMTerminateUserWithoutUserInCUCM {
    param(
        [Parameter(Mandatory)]$PhoneName
    )

    $PhoneSearchResults = Find-CUCMPhone -Name $PhoneName
    $DeviceNames = $PhoneSearchResults.name
    $Phones = foreach ($DeviceName in $DeviceNames) { Get-CUCMPhone -Name $DeviceName }
    $Lines = $Phones.lines.line

    ForEach ($DirectoryNumber in $Lines.dirn ) { 
        $SetCUCMLineResponse = Set-CUCMLine -Pattern $DirectoryNumber.Pattern -RoutePartitionName $DirectoryNumber.routePartitionName."#text" -Description "" -AlertingName "" -AsciiAlertingName ""

    }
  
   $RemoveCUCMPhoneResponse = $Phones | Remove-CUCMPhone
   $RemoveCUCMPhoneResponse
}
    

Function Invoke-TervisCUCMTerminateUser {
    param(
        [Parameter(Mandatory)]$UserName
    )

    $CUCMUser = Get-CUCMUser -UserID $UserName
    $DeviceNames = $CUCMUser.associatedDevices.device
    $Phones = foreach ($DeviceName in $DeviceNames) { Get-CUCMPhone -Name $DeviceName }
    $Lines = $Phones.lines.line

    ForEach ($DirectoryNumber in $Lines.dirn ) { 
        $SetCUCMLineResponse = Set-CUCMLine -Pattern $DirectoryNumber.Pattern -RoutePartitionName $DirectoryNumber.routePartitionName."#text" -Description "" -AlertingName "" -AsciiAlertingName "" 
    }

    $RemoveCUCMPhoneResponse = $Phones | Remove-CUCMPhone
    $RemoveCUCMPhoneResponse
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
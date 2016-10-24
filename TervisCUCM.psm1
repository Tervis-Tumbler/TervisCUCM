#Requires -Modules CUCMPowerShell

function Install-TervisCUCM {
    New-TervisCUCMCredential    
}

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

function Add-CallcenterAgent {

    param(
         [Parameter(Mandatory)][String]$UserName
    )

    Add-CUCMPhone -UserID $UserName
    Set-CUCMUser -UserID $UserName
    Set-CUCMIPCCExtension -UserID $UserName

    }

function Set-CUCMAgentLine  {

     param  (
        [Parameter(Mandatory)][String]$Pattern,
        #[Parameter(Mandatory)][String]$UserID,
        [Parameter(Mandatory)][String]$routePartition,
        [Parameter(Mandatory)][String]$CSS,
        [String]$Description,
        [String]$AlertingName,
        [String]$AsciiAlertingName,
        [String]$voiceMailProfileName,
        $userHoldMohAudioSourceId,
        $networkHoldMohAudioSourceId,
        $CallForwardAllForwardToVoiceMail,
        $CallForwardAllcallingSearchSpaceName,
        $CallForwardAllsecondarycallingSearchSpaceName,
        $CallForwardBusyForwardToVoiceMail,
        $CallForwardBusycallingSearchSpaceName,
        $CallForwardBusyIntForwardToVoiceMail,
        $CallForwardBusyIntcallingSearchSpaceName,
        $callForwardNoAnswerForwardToVoiceMail,
        $callForwardNoAnswercallingSearchSpaceName,
        $CallForwardNoAnswerIntForwardToVoiceMail,
        $CallForwardNoAnswerIntcallingSearchSpaceName,
        $callForwardNoCoverageForwardToVoiceMail,
        $callForwardNoCoveragecallingSearchSpaceName,
        $callForwardNoCoverageIntForwardToVoiceMail,
        $callForwardNoCoverageIntcallingSearchSpaceName,
        $callForwardOnFailureForwardToVoiceMail,
        $callForwardOnFailurecallingSearchSpaceName,
        $callForwardNotRegisteredForwardToVoiceMail,
        $callForwardNotRegisteredcallingSearchSpaceName,
        $callForwardNotRegisteredIntForwardToVoiceMail,
        $callForwardNotRegisteredIntcallingSearchSpaceName,
        $index,
        [String]$display
    
      )


$AXL = @"

<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/9.1">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:updateLine sequence="?">
         <pattern>$Pattern</pattern>
         <routePartitionName>$routePartition</routePartitionName>
         <description>$Description</description>
         <alertingName>$alertingName</alertingName>
         <asciiAlertingName>$asciiAlertingName</asciiAlertingName>
         <voiceMailProfileName>$voiceMailProfileName</voiceMailProfileName>
         <shareLineAppearanceCssName>$CSS</shareLineAppearanceCssName>
         <userHoldMohAudioSourceId>$userHoldMohAudioSourceId</userHoldMohAudioSourceId>
         <networkHoldMohAudioSourceId>$networkHoldMohAudioSourceId</networkHoldMohAudioSourceId>
         $(
         if ($CallForwardAllForwardToVoiceMail) {
         "<callForwardAll>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardAllForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardAllcallingSearchSpaceName -AsString)
                   $(New-XMLElement -Name secondaryCallingSearchSpaceName  -InnerText $CallForwardAllsecondarycallingSearchSpaceName -AsString)
         "</callForwardAll>" 
         }
         )
         $(
         if ($CallForwardBusyForwardToVoiceMail) {
         "<callForwardBusy>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardBusyForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardBusycallingSearchSpaceName -AsString)
         "</callForwardBusy>"
         }
         )
         $(
         if ($CallForwardBusyIntForwardToVoiceMail) {
         "<callForwardBusyInt>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardBusyIntForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardBusyIntcallingSearchSpaceName -AsString)
         "</callForwardBusyInt>"
         }
         )
         $(
         if ($CallForwardNoAnswerForwardToVoiceMail) {
         "<callForwardNoAnswer>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNoAnswerForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardNoAnswercallingSearchSpaceName -AsString)
         "</callForwardNoAnswer>"
         }
         )
         $(
         if ($CallForwardNoAnswerIntForwardToVoiceMail) {
         "<callForwardNoAnswerInt>"
                    $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNoAnswerIntForwardToVoiceMail -AsString)                   
                    $(New-XMLElement -Name callingSearchSpaceName -InnerText $CallForwardNoAnswerIntcallingSearchSpaceName -AsString)
         "</callForwardNoAnswerInt>"
         }
         )
         $(
         if ($CallForwardNoCoverageForwardToVoiceMail) {
         "<callForwardNoCoverage>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNoCoverageForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardNoCoveragecallingSearchSpaceName -AsString)
         "</callForwardNoCoverage>"
         }
         )
         $(
         if ($CallForwardNoCoverageIntForwardToVoiceMail) {
         "<callForwardNoCoverageInt>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNoCoverageIntForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardNoCoverageIntcallingSearchSpaceName -AsString)
         "</callForwardNoCoverageInt>"
         }
         )
         $(
         if ($CallForwardOnFailureForwardToVoiceMail) {
         "<callForwardOnFailure>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardOnFailureForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardOnFailurecallingSearchSpaceName -AsString)
         "</callForwardOnFailure>"
         }
         )
         $(
         if ($CallForwardNotRegisteredForwardToVoiceMail) {
         "<callForwardNotRegistered>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNotRegisteredForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName  -InnerText $CallForwardNotRegisteredcallingSearchSpaceName -AsString)
         "</callForwardNotRegistered>"
         }
         )
         $(
         if ($CallForwardNotRegisteredIntForwardToVoiceMail) {
         "<callForwardNotRegisteredInt>"
                   $(New-XMLElement -Name forwardToVoiceMail -InnerText $CallForwardNotRegisteredIntForwardToVoiceMail -AsString)
                   $(New-XMLElement -Name callingSearchSpaceName -InnerText $CallForwardNotRegisteredIntcallingSearchSpaceName -AsString)
         "</callForwardNotRegisteredInt>"
         }
         )
         <Lines>
         <lineIdentifier>
         <index>$index</index>
         <display>$display</display>
         </lineIdentifier>
         </Lines>
    </ns:updateLine>
    </soapenv:Body>
</soapenv:Envelope>

"@
   
     $XmlContent = Invoke-CUCMSOAPAPIFunction -AXL $AXL -MethodName updateLine
     $XmlContent.Envelope.Body.updateLineResponse.return
    
    
}

function New-TervisCUCMCredential {
    New-CUCMCredential -CUCMCredential $(Get-PasswordstateCredential -PasswordID 15)
}

Function Remove-TervisCUCMUser {
    param(
        $UserName
    )

    $QueryResult = Get-CUCMDeviceName -UserIDAssociatedWithDevice $UserName
    $Result = Remove-CUCMPhone -Name $QueryResult.name
    Set-CUCMLine -DN 
}
# REMOVE BEFORE LIVE VERSION - THIS SHOULD ONLY BE HERE FOR TESTING
$Username = "logicapi@logicplus.com.au"
$Password = "f3KknnU#w}"

# Configure Variables - Set API, New WebRequestSession
$APIURL = "https://ncentral.logicplus.com.au/dms2/services2/ServerEI2?wsdl"

# Set Customer ID
$CustomerID = 50

# SOAP Envelope - This appears to be similar but different for each request - this is for: deviceList
$SOAPBody = @"
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ei2="http://ei2.nobj.nable.com/">
   <soap:Header/>
   <soap:Body>
      <ei2:deviceList>
         <!--Optional:-->
         <ei2:username>$Username</ei2:username>
         <!--Optional:-->
         <ei2:password>$Password</ei2:password>
         <!--Zero or more repetitions:-->
         <ei2:settings>
            <!--Optional:-->
            <ei2:first></ei2:first>
            <!--Optional:-->
            <ei2:second></ei2:second>
            <!--Optional:-->
            <ei2:key>customerID</ei2:key>
            <!--Optional:-->
            <ei2:value>$CustomerID</ei2:value>
         </ei2:settings>
      </ei2:deviceList>
   </soap:Body>
</soap:Envelope>
"@

# Parameters for API
$POSTParams = @{username="$Username";password="$Password";key="customerID";value="$CustomerID"}

# Invoke web request and get XML return
$DeviceList = Invoke-WebRequest -Uri $APIURL -Body $SOAPBody -Headers $POSTParams -ContentType "text/xml" -Method POST

# Variable that looks at the data returned.
$Devices = $([XML]$DeviceList.Content).Envelope.Body.deviceListResponse.return

# Create PowerShell Custom Object - for ease of use.
$ReadableDevices = ForEach ($Line in $Devices){
    Write-Progress -Activity "Putting Devices into PowerShell Custom Object..." -Status "Record $I of $($Devices.Count)" -PercentComplete (($I/$Devices.Count)*100)
    If ($Testing -eq $True) {
        For ($Keys = 0; $Keys -lt $Devices[$I].items.key.Count; $Keys++){
            Write-Host "$($Devices[$I].items.key[$Keys]) = $($Devices[$I].items.value[$Keys])" -BackgroundColor Black -ForegroundColor Gray
        }
    }
    $Properties = @{
        deviceid = ($Devices[$I].items | Where-Object {$_.key -eq 'device.deviceid'}).value
        uri = ($Devices[$I].items | Where-Object {$_.key -eq 'device.uri'}).value.ToLower()
        remotecontroluri = ($Devices[$I].items | Where-Object {$_.key -eq 'device.remotecontroluri'}).value
        sourceuri = ($Devices[$I].items | Where-Object {$_.key -eq 'device.sourceuri'}).value
        longname = ($Devices[$I].items | Where-Object {$_.key -eq 'device.longname'}).value
        deviceclass = ($Devices[$I].items | Where-Object {$_.key -eq 'device.deviceclass'}).value
        description = ($Devices[$I].items | Where-Object {$_.key -eq 'device.description'}).value
        isprobe = ($Devices[$I].items | Where-Object {$_.key -eq 'device.isprobe'}).value
        agentversion = ($Devices[$I].items | Where-Object {$_.key -eq 'device.agentversion'}).value
        interfaceversion = ($Devices[$I].items | Where-Object {$_.key -eq 'device.interfaceversion'}).value
        networkversion = ($Devices[$I].items | Where-Object {$_.key -eq 'device.networkversion'}).value
        osid = ($Devices[$I].items | Where-Object {$_.key -eq 'device.osid'}).value
        supportedos = ($Devices[$I].items | Where-Object {$_.key -eq 'device.supportedos'}).value
        discoveredname = If ($Null -ne ($Devices[$I].items | Where-Object {$_.key -eq 'device.discoveredname'}).value) {($Devices[$I].items | Where-Object {$_.key -eq 'device.discoveredname'}).value.ToUpper()} Else {$Null}
        statestatus = ($Devices[$I].items | Where-Object {$_.key -eq 'device.statestatus'}).value
        deviceclasslabel = ($Devices[$I].items | Where-Object {$_.key -eq 'device.deviceclasslabel'}).value
        supportedoslabel = ($Devices[$I].items | Where-Object {$_.key -eq 'device.supportedoslabel'}).value
        lastloggedinuser = ($Devices[$I].items | Where-Object {$_.key -eq 'device.lastloggedinuser'}).value
        stillloggedin = ($Devices[$I].items | Where-Object {$_.key -eq 'device.stillloggedin'}).value
        licensemode = ($Devices[$I].items | Where-Object {$_.key -eq 'device.licensemode'}).value
        soname = ($Devices[$I].items | Where-Object {$_.key -eq 'device.soname'}).value
        customername = ($Devices[$I].items | Where-Object {$_.key -eq 'device.customername'}).value
        sitename = If ($Devices[$I].items.key -contains 'device.sitename') {($Devices[$I].items | Where-Object {$_.key -eq 'device.sitename'} -ErrorAction Stop).value} Else {"---"}
}

    New-Object -TypeName PSCustomObject -Property $Properties
}

# Filter 
$ReadableDevices | Sort-Object sitename, deviceclass, discoveredname | Format-Table customername, sitename, deviceclass, discoveredname, uri, isprobe, statestatus -AutoSize
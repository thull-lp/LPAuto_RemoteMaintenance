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
    $Properties = @{
        deviceid = $Line.items.value[0]
        uri = $Line.items.value[1].ToLower()
        remotecontroluri = $Line.items.value[2]
        sourceuri = $Line.items.value[3]
        longname = $Line.items.value[4]
        deviceclass = $Line.items.value[5]
        description = $Line.items.value[6]
        isprobe = $Line.items.value[7]
        agentversion = $Line.items.value[8]
        interfaceversion = $Line.items.value[9]
        networkversion = $Line.items.value[10]
        osid = $Line.items.value[11]
        supportedos = $Line.items.value[12]
        discoveredname = $Line.items.value[13].ToUpper()
        statestatus = $Line.items.value[14]
        deviceclasslabel = $Line.items.value[15]
        supportedoslabel = $Line.items.value[16]
        lastloggedinuser = $Line.items.value[17]
        stillloggedin = $Line.items.value[18]
        licensemode = $Line.items.value[19]
        soname = $Line.items.value[20]
        customername = $Line.items.value[21]
        sitename = $Line.items.value[22]
    }

    New-Object -TypeName PSCustomObject -Property $Properties
}


# Filter 
$ReadableDevices | Sort-Object sitename, deviceclass, discoveredname | Format-Table customername, sitename, deviceclass, discoveredname, uri, isprobe, statestatus -AutoSize
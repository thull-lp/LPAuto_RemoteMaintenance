# REMOVE BEFORE LIVE VERSION - THIS SHOULD ONLY BE HERE FOR TESTING
$Username = "logicapi@logicplus.com.au"
$Password = "f3KknnU#w}"

# Configure Variables - Set API, New WebRequestSession
$APIURL = "https://ncentral.logicplus.com.au/dms2/services2/ServerEI2?wsdl"

# Set Customer ID
$CustomerID = 50

# SOAP Envelope - This appears to be similar but different for each request - this is for: activeIssuesList
$SOAPBody = @"
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ei2="http://ei2.nobj.nable.com/">
   <soap:Header/>
   <soap:Body>
      <ei2:activeIssuesList>
         <!--Optional:-->
         <ei2:username>$Username</ei2:username>
         <!--Optional:-->
         <ei2:password>$Password</ei2:password>
         <!--Zero or more repetitions:-->
         <ei2:settings>
            <!--Optional:-->
            <ei2:key>customerID</ei2:key>
            <!--Optional:-->
            <ei2:value>$CustomerID</ei2:value>
         </ei2:settings>
      </ei2:activeIssuesList>
   </soap:Body>
</soap:Envelope>
"@

# Parameters for API
$POSTParams = @{username="$Username";password="$Password";key="customerID";value="$CustomerID"}

# Invoke web request and get XML return
$ActiveIssues = Invoke-WebRequest -Uri $APIURL -Body $SOAPBody -Headers $POSTParams -ContentType "text/xml" -Method POST

# Variable that looks at the data returned.
$Issues = $([XML]$ActiveIssues.Content).Envelope.Body.activeIssuesListResponse.return

# Create PowerShell Custom Object - for ease of use.
$ReadableIssues = ForEach ($Line in $Issues){
    $Properties = @{
        socustomername = $Line.items.value[0]
        customername = $Line.items.value[1]
        sitename = $Line.items.value[2]
        customerid = $Line.items.value[3]
        socustomerid = $Line.items.value[4]
        deviceid = $Line.items.value[5]
        devicename = $Line.items.value[6]
        deviceclass = $Line.items.value[7]
        licensemode = $Line.items.value[8]
        isremotecontrollable = $Line.items.value[9]
        notifstate = Switch($Line.items.value[10]) {"4" {"Warning"} "5" {"Failed"} "6" {"Misconfigured"} "7" {"Disconnected"} "8" {"Disabled"}}
        servicename = $Line.items.value[11]
        serviceid = $Line.items.value[12]
        taskid = $Line.items.value[13]
        taskident = $Line.items.value[14]
        transitiontime = $Line.items.value[15]
        ispartofnotification = $Line.items.value[16]
        numberofactivenotification = $Line.items.value[17]
        numberofacknowledgednotification = $Line.items.value[18]
        serviceitemid = $Line.items.value[19]
        isremotecontrolconnected = $Line.items.value[20]
        psaintegrationexists = $Line.items.value[21]
        psaticketdetails = $Line.items.value[22]
    }

    New-Object -TypeName PSCustomObject -Property $Properties
}

# Filter 
$ReadableIssues | Where-Object {$_.notifstate -ne "Disabled"} | Format-Table customername, sitename, deviceclass, devicename, servicename, notifstate -AutoSize
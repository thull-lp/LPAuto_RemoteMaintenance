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
        socustomername = ($Line.items | Where-Object {$_.key -eq 'activeissue.socustomername'}).value
        customername = ($Line.items | Where-Object {$_.key -eq 'activeissue.customername'}).value
        sitename = ($Line.items | Where-Object {$_.key -eq 'activeissue.SITE_NAME'}).value
        customerid = ($Line.items | Where-Object {$_.key -eq 'activeissue.customerid'}).value
        socustomerid = ($Line.items | Where-Object {$_.key -eq 'activeissue.socustomerid'}).value
        deviceid = ($Line.items | Where-Object {$_.key -eq 'activeissue.deviceid'}).value
        devicename = ($Line.items | Where-Object {$_.key -eq 'activeissue.devicename'}).value
        deviceclass = ($Line.items | Where-Object {$_.key -eq 'activeissue.deviceclass'}).value
        licensemode = ($Line.items | Where-Object {$_.key -eq 'activeissue.licensemode'}).value
        isremotecontrollable = ($Line.items | Where-Object {$_.key -eq 'activeissue.isremotecontrollable'}).value
        notifstate = Switch(($Line.items | Where-Object {$_.key -eq 'activeissue.notifstate'}).value) {"0" {"No State"} "1" {"No Data"} "2" {"Stale"} "3" {"Normal"} "4" {"Warning"} "5" {"Failed"} "6" {"Misconfigured"} "7" {"Disconnected"}}
        servicename = ($Line.items | Where-Object {$_.key -eq 'activeissue.servicename'}).value
        serviceid = ($Line.items | Where-Object {$_.key -eq 'activeissue.serviceid'}).value
        taskid = ($Line.items | Where-Object {$_.key -eq 'activeissue.taskid'}).value
        taskident = ($Line.items | Where-Object {$_.key -eq 'activeissue.taskident'}).value
        transitiontime = ($Line.items | Where-Object {$_.key -eq 'activeissue.transitiontime'}).value
        ispartofnotification = ($Line.items | Where-Object {$_.key -eq 'activeissue.ispartofnotification'}).value
        numberofactivenotification = ($Line.items | Where-Object {$_.key -eq 'activeissue.numberofactivenotification'}).value
        numberofacknowledgednotification = ($Line.items | Where-Object {$_.key -eq 'activeissue.numberofacknowledgednotification'}).value
        serviceitemid = ($Line.items | Where-Object {$_.key -eq 'activeissue.serviceitemid'}).value
        isremotecontrolconnected = ($Line.items | Where-Object {$_.key -eq 'activeissue.isremotecontrolconnected'}).value
        psaintegrationexists = ($Line.items | Where-Object {$_.key -eq 'activeissue.psaintegrationexists'}).value
        psaticketdetails = ($Line.items | Where-Object {$_.key -eq 'activeissue.psaticketdetails'}).value
    }

    New-Object -TypeName PSCustomObject -Property $Properties
}

# Filter 
$ReadableIssues | Where-Object {$_.notifstate -ne "Disabled"} | Format-Table customername, sitename, deviceclass, devicename, servicename, taskident, notifstate -AutoSize
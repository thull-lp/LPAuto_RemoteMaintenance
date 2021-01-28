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
            <ei2:first></ei2:first>
            <!--Optional:-->
            <ei2:second></ei2:second>
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
        socustomername = $Line.issue.value[0]
        customername = $Line.issue.value[1]
        sitename = $Line.issue.value[2]
        customerid = $Line.issue.value[3]
        socustomerid = $Line.issue.value[4]
        deviceid = $Line.issue.value[5]
        devicename = $Line.issue.value[6]
        deviceclass = $Line.issue.value[7]
        licensemode = $Line.issue.value[8]
        isremotecontrollable = $Line.issue.value[9]
        notifstate = Switch($Line.issue.value[10]) {"4" {"Warning"} "5" {"Failed"} "6" {"Misconfigured"} "7" {"Disconnected"} "8" {"Disabled"}}
        servicename = $Line.issue.value[11]
        serviceid = $Line.issue.value[12]
        taskid = $Line.issue.value[13]
        taskident = $Line.issue.value[14]
        transitiontime = $Line.issue.value[15]
        ispartofnotification = $Line.issue.value[16]
        numberofactivenotification = $Line.issue.value[17]
        numberofacknowledgednotification = $Line.issue.value[18]
        serviceitemid = $Line.issue.value[19]
        isremotecontrolconnected = $Line.issue.value[20]
        psaintegrationexists = $Line.issue.value[21]
        psaticketdetails = $Line.issue.value[22]
    }

    New-Object -TypeName PSCustomObject -Property $Properties
}

# Filter 
$ReadableIssues | Where-Object {$_.notifstate -ne "Disabled"} | Format-Table customername, sitename, deviceclass, devicename, servicename, notifstate -AutoSize
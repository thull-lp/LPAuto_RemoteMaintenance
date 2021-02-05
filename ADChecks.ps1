Import-Module ActiveDirectory

# Variables
$DateStamp = (Get-Date).ToString('dd-MM-yyyy')
$ReportDateStamp = (Get-Date).ToString('MMMM yyyy')

# Parameters
$MaintPath = "C:\Support\Maintenance"
$ConfigPath = "$MaintPath\Configuration Files"
$ReportPath = "$MaintPath\Reports"

$AOKColours = @{BackgroundColor="Black"; ForegroundColor="Green"}
$ErrorColours = @{BackgroundColor="Black"; ForegroundColor="Red"}
$WarnColours = @{BackgroundColor="Black"; ForegroundColor="Yellow"}

$ADDomain = (Get-ADDomain).DistinguishedName

# Clear flags - mainly for testing.
$FirstRun = $Null

# Test and create folders if not present.
$TestMaintPath = Test-Path $MaintPath
$TestMaintRepPath = Test-Path $ReportPath
$TestMaintConfPath = Test-Path $ConfigPath

If ($TestMaintPath -eq $False) {
    Write-Host "Maintenance Folder Missing, creating... " @ErrorColours -NoNewline
    New-Item -Path "C:\Support\" -Name "Maintenance" -ItemType Directory | Out-Null
    Write-Host "... Created!" @AOKColours
}

If ($TestMaintRepPath -eq $False) {
    Write-Host "Reports Folder Missing, creating... " @ErrorColours -NoNewline
    New-Item -Path $MaintPath -Name "Reports" -ItemType Directory | Out-Null
    Write-Host "... Created!" @AOKColours
}

If ($TestMaintConfPath -eq $False) {
    Write-Host "Configuration Folder Missing, creating... " @ErrorColours -NoNewline
    New-Item -Path $MaintPath -Name "Configuration Files" -ItemType Directory | Out-Null
    Write-Host "... Created!" @AOKColours
}

# Import information from config files
# Exclude OUs
Try {
    $ExcludeOUs = Import-Csv "$ConfigPath\ADMaintenanceConfig-ExcludeOUs.csv" -ErrorAction Stop
} Catch {
    Write-Host "Configuration File Missing - Exclude OUs, creating default..." @ErrorColours
    $DefaultOUs = @(
        "CN=Users,$ADDomain"
    )
    $ExcludeOUs = @()
    ForEach ($OU in $DefaultOUs){
        $ExcludeOUs += [PSCustomObject]@{
            DistinguishedName = $OU
            TicketNo = "DEFAULT"
        }
    }
    $ExcludeOUs | Export-Csv -Path "$ConfigPath\ADMaintenanceConfig-ExcludeOUs.csv" -NoTypeInformation
} Finally {
    $ExcludeOUs = Import-Csv "$ConfigPath\ADMaintenanceConfig-ExcludeOUs.csv"
}

# Exclude Users
Try {
    $ExcludeUsers = Import-Csv "$ConfigPath\ADMaintenanceConfig-ExcludeUsers.csv" -ErrorAction Stop
} Catch {
    Write-Host "Configuration File Missing - Exclude Users, creating default..." @ErrorColours
    $DefaultUsers = @(
        "_svc",
        "Administrator",
        "adsync",
        "logicplus",
        "lp",
        "lpadmin",
        "svc_",
        "veeam"
    )
    $ExcludeUsers = @()
    ForEach ($User in $DefaultUsers){
        $ExcludeUsers += [PSCustomObject]@{
            SamAccountName = $User
            TicketNo = "DEFAULT"
        }
    }
    $ExcludeUsers | Export-Csv -Path "$ConfigPath\ADMaintenanceConfig-ExcludeUsers.csv" -NoTypeInformation
} Finally {
    $ExcludeUsers = Import-Csv "$ConfigPath\ADMaintenanceConfig-ExcludeUsers.csv"
}

# Known/Previously Identified Issues
Try {
    $KnownIssues = Import-Csv "$ConfigPath\ADMaintenanceConfig-KnownIssues.csv" -ErrorAction Stop
} Catch {
    Write-Host "Configuration File Missing - Known Issues, this must be a first run, setting flag and noting issues." @WarnColours
    $FirstRun = $True
} 

# If this isn't our first run, import known/idenfitifed but ignored issues.
If ($Null -eq $FirstRun) {
    $ExcludeUsers += ($KnownIssues | Where-Object {($_.Exclude -eq $True) -and ($_.TicketNo -ne $Null)} | Sort-Object SamAccountName -Unique | Select-Object SamAccountName, TicketNo)
}

# Join arrays into Regex Pattern - i.e. Administrator|lpadmin|logicplus|svc_ etc.
$ExcludedUsersPattern = ($ExcludeUsers | Sort-Object SamAccountName).SamAccountName -Join "|"
$ExcludedOUsPattern = ($ExcludeOUs | Sort-Object DistinguishedName).DistinguishedName -Join "|"

# Perform the checks!
# Get all enabled users:
$EnabledADUsers = Get-ADUser -Filter * -Properties * | Where-Object {$_.Enabled -eq $True}

# Filter Parse 1 - Strip out the excluded users and OUs.
$FilteredADUsers = $EnabledADUsers | Where-Object {($_.SamAccountName -notmatch $ExcludedUsersPattern) -and ($_.DistinguishedName -notmatch $ExcludedOUsPattern)}

# Filter Parse 2 - Perform the checks and criteria.
# Fitler Parse 2a - Unused AD User Accounts - Last Logon Date older than 60 days or never logged on.
$60DayReport = $FilteredADUsers | Where-Object {($_.LastLogonDate -lt (Get-Date).AddDays(-60)) -or ($Null -eq $_.LastLogonDate)}

# Filter Parse 2b - Password set to never expire.
$NoPwdExpiry = $FilteredADUsers | Where-Object {($_.PasswordNeverExpires -eq $True)}

# Output - create config file if not present, or report for the month.
# Useful for testing: | FT DisplayName, SamAccountName, DistinguishedName, Enabled, LastLogonDate, PasswordNeverExpires, PasswordLastSet
$ADReport = @()

ForEach ($Item in $60DayReport){
    $ADReport += [PSCustomObject]@{
        DisplayName = $Item.DisplayName
        SamAccountName = $Item.SamAccountName
        Exclude = $False
        TicketNo = $Null
        Date = $DateStamp
        Notes = "PWSH - Noted in Automated Maintenance Check."
        BreachCode = If ($_.LastLogonDate -lt (Get-Date).AddDays(-60)) {".AD.UNUSED.ACC.CHK.60DAYS"} `
            ElseIf ($Null -eq $_.LastLogonDate) {".ADUNUSED.ACC.CHK.NULL"} `
            Else {".ADUNUSED.ACC.CHK.OTHER"}
        BreachReason = If ($_.LastLogonDate -lt (Get-Date).AddDays(-60)) {"Unused Account Check - User has not signed in over 60 days."} `
            ElseIf ($Null -eq $_.LastLogonDate) {"Unused Account Check - User has never signed in."} `
            Else {"Unused Account Check - Other or unknown."}
    }
}

ForEach ($Item in $NoPwdExpiry){
    $ADReport += [PSCustomObject]@{
        DisplayName = $Item.DisplayName
        SamAccountName = $Item.SamAccountName
        Exclude = $False
        TicketNo = $Null
        Date = $DateStamp
        Notes = "PWSH - Noted in Automated Maintenance Check."
        BreachCode = ".AD.PWD.EXP.CHK.NEVEREXP"
        BreachReason = "Password Expiry Check - Password set to never expire."
    }
}

# If this is the first run, create a config file, we can then copy items from here to Exclude Users (when they have a ticket number), or Administrative override and exclude from here.
If ($FirstRun -eq $True){
    $ADReport | Export-Csv "$ConfigFilePath\ADMaintenanceConfig-KnownIssues.csv" -NoTypeInformation
}

# Otherwise, this isn't a first run, so this is an actual report, output to reports.
If ($Null -ne $FirstRun) {
    $ADReport | Export-Csv "$ReportPath\Maintenance-ADCheck-$ReportDateStamp.csv" -NoTypeInformation
}

$Output = $ADReport | ForEach-Object {"$($_.DisplayName) - $($_.BreachReason)"}
$OutputCount = $Output.Count
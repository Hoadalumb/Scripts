# Define Compliance Check Results
$ComplianceResults = @{}

# Check Defender for Endpoint Sensor Status
$SenseService = Get-Service -Name sense -ErrorAction SilentlyContinue
$ComplianceResults["EDRSensorRunning"] = if ($SenseService.Status -eq "Running") { $true } else { $false }

# Check Real-Time Protection Status
$RealTimeProtection = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
$ComplianceResults["RealTimeProtectionDisabled"] = if ($RealTimeProtection -eq $false) { $true } else { $false }

# Check Tamper Protection Status
$TamperProtection = (Get-MpComputerStatus).IsTamperProtected
$ComplianceResults["TamperProtectionEnabled"] = if ($TamperProtection -eq $true) { $true } else { $false }

# Check Windows Defender Firewall Status
$FirewallProfiles = Get-NetFirewallProfile | Select-Object Name, Enabled
$FirewallEnabled = $FirewallProfiles | Where-Object { $_.Enabled -eq "True" }
$ComplianceResults["DefenderFirewallEnabled"] = if ($FirewallEnabled) { $true } else { $false }

# Check Network Protection Status (Audit Mode)
$NetworkProtection = Get-MpPreference | Select-Object -ExpandProperty EnableNetworkProtection
$ComplianceResults["NetworkProtectionEnabled"] = if ($NetworkProtection -eq 2) { $true } else { $false }

# Check PUA Protection Status
$PUAProtection = Get-MpPreference | Select-Object -ExpandProperty PUAProtection
$ComplianceResults["PUAProtectionEnabled"] = if ($PUAProtection -eq 1) { $true } else { $false }

# Check Cloud Protection Status
$CloudProtection = Get-MpPreference | Select-Object -ExpandProperty CloudBlockLevel
$ComplianceResults["CloudProtectionEnabled"] = if ($CloudProtection -eq 2) { $true } else { $false }

# Check MAPS Reporting Status
$MAPSReporting = Get-MpPreference | Select-Object -ExpandProperty MAPSReporting
$ComplianceResults["MAPSReportingEnabled"] = if ($MAPSReporting -eq 2) { $true } else { $false }

# Check Sample Submission Status
$SampleSubmission = Get-MpPreference | Select-Object -ExpandProperty SubmitSamplesConsent
$ComplianceResults["SampleSubmissionEnabled"] = if ($SampleSubmission -eq 2) { $true } else { $false }

# Output as JSON for Intune Custom Compliance
$ComplianceResults | ConvertTo-Json -Compress

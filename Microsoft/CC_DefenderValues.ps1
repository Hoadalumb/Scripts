# Define Compliance Check Results
$ComplianceResults = @{}

# 1️⃣ Check Defender for Endpoint Sensor Status
$SenseService = Get-Service -Name sense -ErrorAction SilentlyContinue
$ComplianceResults["EDRSensorRunning"] = if ($SenseService.Status -eq "Running") { $true } else { $false }

# 2️⃣ Check Cloud Connection Status
$CloudStatus = Get-MpComputerStatus | Select-Object -ExpandProperty IsCloudConnected
$ComplianceResults["CloudConnected"] = if ($CloudStatus -eq $true) { $true } else { $false }

# 3️⃣ Check Security Intelligence Updates
$SecurityIntelligenceVersion = Get-MpComputerStatus | Select-Object -ExpandProperty SecurityIntelligenceVersion
$ComplianceResults["SecurityIntelligenceVersion"] = $SecurityIntelligenceVersion

# 4️⃣ Check Real-Time Protection Status
$RealTimeProtection = Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring
$ComplianceResults["RealTimeProtectionEnabled"] = if ($RealTimeProtection -eq $false) { $true } else { $false }

# 5️⃣ Check Attack Surface Reduction (ASR) Rules
$ASRRules = Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Actions
$ASRBlocking = if ($ASRRules -contains 1) { $true } else { $false }
$ComplianceResults["ASRBlockingEnabled"] = $ASRBlocking

# 6️⃣ Check Tamper Protection Status
$TamperProtection = (Get-MpComputerStatus).IsTamperProtected
$ComplianceResults["TamperProtectionEnabled"] = if ($TamperProtection -eq $true) { $true } else { $false }

# 7️⃣ Check Windows Defender Firewall Status
$FirewallProfiles = Get-NetFirewallProfile | Select-Object Name, Enabled
$FirewallEnabled = $FirewallProfiles | Where-Object { $_.Enabled -eq "True" }
$ComplianceResults["DefenderFirewallEnabled"] = if ($FirewallEnabled) { $true } else { $false }

# 8️⃣ Check Network Protection Status
$NetworkProtection = Get-MpPreference | Select-Object -ExpandProperty EnableNetworkProtection
$ComplianceResults["NetworkProtectionEnabled"] = if ($NetworkProtection -eq 1) { $true } else { $false }

# 9️⃣ Check Defender for Endpoint Cloud Reporting (EDR)
$EDRStatus = Get-MpComputerStatus | Select-Object -ExpandProperty EDRProtectionPolicyApplied
$ComplianceResults["EDRReportingEnabled"] = if ($EDRStatus -eq $true) { $true } else { $false }

# 🔟 Check Controlled Folder Access (Ransomware Protection)
$ControlledFolderAccess = Get-MpPreference | Select-Object -ExpandProperty EnableControlledFolderAccess
$ComplianceResults["ControlledFolderAccessEnabled"] = if ($ControlledFolderAccess -eq 1) { $true } else { $false }

# 1️⃣1️⃣ Check Last Defender Scan Time
$LastQuickScan = (Get-MpComputerStatus).LastQuickScanStartTime
$LastFullScan = (Get-MpComputerStatus).LastFullScanStartTime
$ComplianceResults["LastQuickScan"] = $LastQuickScan
$ComplianceResults["LastFullScan"] = $LastFullScan

# Output as JSON for Intune Custom Compliance
$ComplianceResults | ConvertTo-Json -Compress

# Install and import necessary modules
Install-Module -Name Microsoft.Graph.DeviceManagement -Force -AllowClobber
Install-Module -Name Microsoft.Graph.Groups -Force -AllowClobber
Import-Module -Name Microsoft.Graph.Groups
Import-Module -Name Microsoft.Graph.DeviceManagement

# Connect to Microsoft Graph
Connect-MgGraph -Scopes Group.Read.All, DeviceManagementApps.Read.All

# Get all applications with their assignments
Write-Host "Fetching all apps and their assigned groups with assignment type..." -ForegroundColor Cyan
$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"

# Fetch all apps
$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value

# Prompt user for filtering assigned apps
$FilterAssignedApps = Read-Host "Do you want to display only assigned apps? (Yes/No)"

# Prompt user for OS selection with both numbers and names
Write-Host "Available OS types to filter:" -ForegroundColor Cyan
Write-Host "1. iOS VPP" -ForegroundColor Yellow
Write-Host "2. Android Protection Policy" -ForegroundColor Yellow
Write-Host "3. MacOS LOB" -ForegroundColor Yellow
Write-Host "4. Windows LOB" -ForegroundColor Yellow
Write-Host "5. Windows" -ForegroundColor Yellow
Write-Host "6. All OS types (no filter)" -ForegroundColor Yellow
$SelectedOption = Read-Host "Enter the number or name of the OS type you want to display (e.g., '1' or 'iOS VPP')"

# Map number-based selection to OS names
switch ($SelectedOption) {
    "1" { $SelectedOS = "iOS VPP" }
    "2" { $SelectedOS = "Android Protection Policy" }
    "3" { $SelectedOS = "MacOS LOB" }
    "4" { $SelectedOS = "Windows LOB" }
    "5" { $SelectedOS = "Windows" }
    "6" { $SelectedOS = "All" }
    default { $SelectedOS = $SelectedOption } # Assume direct name input for custom entries
}

# Function to infer OS from @odata.type
function Get-OSFromODataType {
    param ($ODataType)

    switch ($ODataType) {
        "#microsoft.graph.iosVppApp" { return "iOS VPP" }
        "#microsoft.graph.managedAndroidStoreApp" { return "Android Protection Policy" }
        "#microsoft.graph.macOSLobApp" { return "MacOS LOB" }
        "#microsoft.graph.win32LobApp" { return "Windows LOB" }
        "#microsoft.graph.windowsUniversalAppX" { return "Windows" }
        "#microsoft.graph.managedIOSStoreApp" { return "iOS Protection Policy" }
        "#microsoft.graph.macOsVppApp" { return "macOS VPP" }
        "#microsoft.graph.macOSPkgApp" { return "macOS PKG" }
        "#microsoft.graph.androidManagedStoreApp" { return "Managed Google Play" }
        "#microsoft.graph.winGetApp" { return "Windows Store" }
        "#microsoft.graph.iosStoreApp" { return "iOS Store" }
        "#microsoft.graph.windowsMicrosoftEdgeApp" { return "Built-in Windows" }
        "#microsoft.graph.macOSMicrosoftDefenderApp" { return "Built-in macOS" }
        default { return "Unknown" }
    }
}

# Initialize an array to store results
$Results = @()

foreach ($App in $Apps) {
    # Extract the @odata.type and infer the OS
    $ODataType = $App."@odata.type"
    $OS = if ($ODataType) { Get-OSFromODataType -ODataType $ODataType } else { "Unknown" }

    # Filter apps based on user selection
    if ($FilterAssignedApps -ieq "Yes" -and -not $App.Assignments) {
        continue # Skip apps with no assignments
    }
    if ($SelectedOS -ne "All" -and $OS -ne $SelectedOS) {
        continue # Skip apps that don't match the selected OS
    }

    # Collect data for output
    $Assignments = if ($App.Assignments) {
        $App.Assignments | ForEach-Object {
            $GroupId = $_.Target.GroupId
            $Intent = $_.Intent
            @{
                "AppName" = $App.DisplayName
                "OS" = $OS
                "GroupName" = if ($GroupId) { (Get-MgGroup -GroupId $GroupId -ErrorAction SilentlyContinue).DisplayName } else { "Unknown" }
                "AssignmentType" = $Intent
            }
        }
    } else {
        @(
            @{
                "AppName" = $App.DisplayName
                "OS" = $OS
                "GroupName" = "None"
                "AssignmentType" = "None"
            }
        )
    }

    $Results += $Assignments
}

# Prompt user to export results
$ExportFilePath = Read-Host "Enter the file path to save the results (e.g., 'C:\AppsReport.csv')"

# Export results to CSV
$Results | Export-Csv -Path $ExportFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Results successfully exported to $ExportFilePath" -ForegroundColor Green

# Disconnect from Microsoft Graph
Disconnect-MgGraph

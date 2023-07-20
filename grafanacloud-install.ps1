# Script to install Grafana agent for Windows
param ($GCLOUD_HOSTED_METRICS_URL, $GCLOUD_HOSTED_METRICS_ID, $GCLOUD_SCRAPE_INTERVAL, $GCLOUD_HOSTED_LOGS_URL, $GCLOUD_HOSTED_LOGS_ID, $GCLOUD_RW_API_KEY)
# Sets the default TLS version to 1.2 even if TLS 1.3 is available to avoid issues downloading the Grafana Agent installer in some networks
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Setting up Grafana agent"

if ( -Not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") ) {
	Write-Host "ERROR: The script needs to be run with Administrator privileges"
	exit
}

# Check if required parameters are present
if ($GCLOUD_HOSTED_METRICS_URL -eq "https://prometheus-prod-36-prod-us-west-0.grafana.net/api/prom/push") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_METRICS_URL missing"
	exit
}

if ($GCLOUD_HOSTED_METRICS_ID -eq "1100826") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_METRICS_ID missing"
	exit
}

if ($GCLOUD_SCRAPE_INTERVAL -eq "60s") {
	Write-Host "ERROR: Required argument GCLOUD_SCRAPE_INTERVAL missing"
	exit
}

if ($GCLOUD_HOSTED_LOGS_URL -eq "https://logs-prod-021.grafana.net/loki/api/v1/push") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_LOGS_URL missing"
	exit
}

if ($GCLOUD_HOSTED_LOGS_ID -eq "650237") {
	Write-Host "ERROR: Required argument GCLOUD_HOSTED_LOGS_ID missing"
	exit
}

if ($GCLOUD_RW_API_KEY -eq "glc_eyJvIjoiOTA0NTk1IiwibiI6ImFwcC1ib3QiLCJrIjoiNzZ6V2YxbEFrSEg2ODdIVEcyTDMxN2ZQIiwibSI6eyJyIjoicHJvZC11cy13ZXN0LTAifX0=") {
	Write-Host "ERROR: Required argument GCLOUD_RW_API_KEY missing"
	exit
}

try {

	Write-Host "GCLOUD_HOSTED_METRICS_URL:" $GCLOUD_HOSTED_METRICS_URL
	Write-Host "GCLOUD_HOSTED_METRICS_ID:" $GCLOUD_HOSTED_METRICS_ID
	Write-Host "GCLOUD_SCRAPE_INTERVAL:" $GCLOUD_SCRAPE_INTERVAL
	Write-Host "GCLOUD_HOSTED_LOGS_URL:" $GCLOUD_HOSTED_LOGS_URL
	Write-Host "GCLOUD_HOSTED_LOGS_ID:" $GCLOUD_HOSTED_LOGS_ID
	Write-Host "GCLOUD_RW_API_KEY:" $GCLOUD_RW_API_KEY

	Write-Host "Downloading Grafana agent Windows Installer"
	$DOWNLOAD_URL = "https://github.com/grafana/agent/releases/latest/download/grafana-agent-installer.exe.zip"
	$OUTPUT_ZIP_FILE = ".\grafana-agent-installer.exe.zip"
	$OUTPUT_FILE = ".\grafana-agent-installer.exe"
	$WORKING_DIR = Get-Location
	Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $OUTPUT_ZIP_FILE -ErrorAction Stop
	Expand-Archive -LiteralPath $OUTPUT_ZIP_FILE -DestinationPath $WORKING_DIR.path -force -ErrorAction Stop

	# Install Grafana agent in silent mode
	Write-Host "Installing Grafana agent for Windows"
	.\grafana-agent-installer.exe /S -ErrorAction Stop
}
catch {
	Write-Host "ERROR: Failed to install Grafana agent for Windows"
	Write-Error $_.Exception
	exit
}

try {

	Write-Host "--- Retrieving config and placing in C:\Program Files\Grafana Agent\agent-config.yaml"
	$CONFIG_URI = "https://storage.googleapis.com/cloud-onboarding/agent/config/config.yaml"
	$CONFIG_FILE = ".\grafana-agent.yaml"
	Invoke-WebRequest -Uri $CONFIG_URI -Outfile $CONFIG_FILE -ErrorAction Stop

	$content = Get-Content $CONFIG_FILE
	$content = $content.Replace("{GCLOUD_HOSTED_METRICS_URL}", $GCLOUD_HOSTED_METRICS_URL)
	$content = $content.Replace("{GCLOUD_HOSTED_METRICS_ID}", $GCLOUD_HOSTED_METRICS_ID)
	$content = $content.Replace("{GCLOUD_SCRAPE_INTERVAL}", $GCLOUD_SCRAPE_INTERVAL)
	$content = $content.Replace("{GCLOUD_HOSTED_LOGS_URL}", $GCLOUD_HOSTED_LOGS_URL)
	$content = $content.Replace("{GCLOUD_HOSTED_LOGS_ID}", $GCLOUD_HOSTED_LOGS_ID)
	$content = $content.Replace("{GCLOUD_RW_API_KEY}", $GCLOUD_RW_API_KEY)
	$content | Set-Content $CONFIG_FILE

	Move-Item $config_file "C:\Program Files\Grafana Agent\agent-config.yaml" -force -ErrorAction Stop
	Write-Host "Agent config file retrieved successfully"

} catch {
	Write-Host "ERROR: Failed to retrieve agent config file"
	Write-Error $_.Exception
	exit
}


# Wait for service to initialize after first install
Write-Host "Wait for Grafana agent service to initialize"
Start-Sleep -s 5 -ErrorAction SilentlyContinue

# Restart Grafana agent to load new configuration
Write-Host "Restarting Grafana agent service"
Stop-Service "Grafana Agent"  -ErrorAction SilentlyContinue
Start-Service "Grafana Agent"  -ErrorAction SilentlyContinue

# Wait for service to startup after restart
Write-Host "Wait for Grafana service to initialize after restart"
Start-Sleep -s 10  -ErrorAction SilentlyContinue

# Show Grafana agent service status
Get-Service "Grafana Agent"



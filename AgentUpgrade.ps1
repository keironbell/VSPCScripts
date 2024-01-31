Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer AddTokenHere")

## Connect to VSPC API and collect info on Veeam Agent Details ##

$Report = Invoke-RestMethod 'https://VSPC-URL/api/v3/infrastructure/backupAgents' -Method 'GET' -Headers $headers

## Get all Veeam Agents that are Managed by Console that have no running backups ## 

$Agents = $Report.data | Where-Object {$_.managementMode -eq "ManagedByConsole" -and $_.runningJobsCount -eq "0"}

## Manually update the current Veeam for Agent Version, nothing in API to show if an upgrade is required, so manual until this is available ##

$CurrentVersion = [Version]"6.1.0.349"

## Create an array and add in if the agent requires an upgrade or not ##

$Table = @()
Foreach($Agent in $Agents)
{

$Name = $agent.name
$Version = [version]$agent.version
$AgentUID = $agent.instanceUid

If($Version -lt $CurrentVersion)
{

    $upgrade = "UpdateRequired"

}
ELSEIF($Version -eq $CurrentVersion)
{
    $upgrade = "UpToDate"
}

$TA = New-Object System.Object

$TA | Add-Member -MemberType NoteProperty -Name Name -Value $Name
$TA | Add-Member -MemberType NoteProperty -Name InstanceUID -Value $AgentUID
$TA | Add-Member -MemberType NoteProperty -Name Version -Value $Version
$Ta | Add-Member -MemberType NoteProperty -Name Update -Value $upgrade

$Table += $TA

}

## Filter out the up to date agents and list only the agents that require an upgade ##

$UpgradeNeeded = $Table | Where-Object {$_.Update -eq "UpdateRequired"}

## For each agent that requires an upgrade, kick the upgrade off ## 

Foreach($Up in $UpgradeNeeded)
{
$upgradeInstanceUID = $up.InstanceUID

    
$UpgradeAgent = Invoke-RestMethod "https://VSPC-URL/api/v3/infrastructure/backupAgents/windows/$UpgradeInstanceUID/update" -Method 'POST' -Headers $headers

}

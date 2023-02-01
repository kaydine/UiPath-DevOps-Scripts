function WriteLog
{
	Param ($message, [switch] $err)
	
	$now = Get-Date -Format "G"
	$line = "$now`t$message"
	$line | Add-Content $debugLog -Encoding UTF8
	if ($err)
	{
		Write-Host $line -ForegroundColor red
	} else {
		Write-Host $line
	}
}

#Running Path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
#log file
$debugLog = "$scriptPath\orchestrator-direct-cli-call.log"
#Verifying UiPath CLI installation
$packageName = "UiPath.CLI.Windows"
$cliVersion = "22.10.8418.30339"; #CLI Version (Script was tested on this latest version at the time)

$uipathCLIFolder = "$scriptPath\uipathcli"
$uipathCLI = "$uipathCLIFolder\tools\uipcli.exe"
if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
    WriteLog "UiPath CLI does not exist in this folder. Attempting to download it..."
    try {
        if (-not(Test-Path -Path "$uipathCLIFolder" -PathType Leaf)){
            New-Item -Path "$uipathCLIFolder" -ItemType "directory" -Force | Out-Null
        }
        #Download UiPath CLI
        $feedUrl = "https://pkgs.dev.azure.com/uipath/Public.Feeds/_packaging/UiPath-Official/nuget/v3/flat2/$packageName/$cliVersion/$packageName.$cliVersion.nupkg"
        $cliZip = "$uipathCLIFolder\cli.zip"
        Invoke-WebRequest "$feedUrl" -OutFile "$cliZip";
        Expand-Archive -LiteralPath "$cliZip" -DestinationPath "$uipathCLIFolder";
        WriteLog "UiPath CLI is downloaded and extracted in folder $uipathCLIFolder"
        Remove-Item $cliZip
        if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
            WriteLog "Unable to locate uipath cli after it is downloaded."
            exit 1
        }
    }
    catch {
        WriteLog ("Error Occured : " + $_.Exception.Message) -err $_.Exception
        exit 1
    }
    
}
WriteLog "-----------------------------------------------------------------------------"
WriteLog "uipcli location :   $uipathCLI"
#END Verifying UiPath CLI installation

$GenericParamList = New-Object 'Collections.Generic.List[string]'
for ( $i = 0; $i -lt $args.count; $i++ ) {
    write-host "Argument  $i is $($args[$i])"
    if($args[$i].StartsWith("-")){
        $GenericParamList.Add($args[$i])
    }
    else {
        $GenericParamList.Add("`"$($args[$i])`"")
        
    }
    
} 
WriteLog "-----------------------------------------------------------------------------"
#call uipath cli 
& "$uipathCLI" $GenericParamList.ToArray()

if($LASTEXITCODE -eq 0)
{
    WriteLog "Done!"
    Exit 0
}else {
    WriteLog "UiPath CLI returns error. Exit code $LASTEXITCODE"
    Exit 1
}
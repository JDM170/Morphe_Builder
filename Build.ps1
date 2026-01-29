<#
    .SYNOPSIS
    Build Morphe app using latest components:
      * YouTube (latest supported);
      * Morphe CLI;
      * Morphe Patches;
      * ReVanced microG GmsCore;
      * Azul Zulu.

    .NOTES
    After compiling, microg.apk and compiled morphe.apk will be located in "Script location folder\ReVanced"

    .LINKS
    https://github.com/MorpheApp
#>

# Requires -Version 5.1
# Doesn't work on PowerShell 7.2 due it doesn't contains IE parser engine. You have to use a 3rd party module to make it work like it's presented in CI/CD config: AngleSharp

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Host.Version.Major -eq 5)
{
    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $Script:ProgressPreference = "SilentlyContinue"
}

# Download all files to "Script location folder\Morphe"
$CurrentFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
if (-not (Test-Path -Path "$CurrentFolder\Morphe"))
{
    New-Item -Path "$CurrentFolder\Morphe" -ItemType Directory -Force
}

Write-Verbose -Message "" -Verbose
Write-Verbose -Message "Downloading Morphe CLI" -Verbose
# https://github.com/MorpheApp/morphe-cli
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/morphe-cli/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url | Select-Object -First 1
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\Morphe\morphe-cli.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

Write-Verbose -Message "" -Verbose
Write-Verbose -Message "Downloading Morphe patches" -Verbose
# https://github.com/MorpheApp/morphe-patches
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/morphe-patches/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/dash-patch+xml"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\Morphe\morphe-patches.mpp"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

Write-Verbose -Message "" -Verbose
Write-Verbose -Message "Downloading Morphe MicroG" -Verbose
# https://github.com/MorpheApp/MicroG-RE
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/MicroG-RE/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/vnd.android.package-archive"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\Morphe\microg.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# Sometimes older version of zulu-jdk causes conflict, so remove older version before proceeding.
if (Test-Path -Path "$CurrentFolder\Morphe\jdk")
{
    Remove-Item -Path "$CurrentFolder\Morphe\jdk" -Recurse -Force
}

Write-Verbose -Message "" -Verbose
Write-Verbose -Message "Downloading Azul Zulu" -Verbose
# https://github.com/ScoopInstaller/Java/blob/master/bucket/zulu-jdk.json
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/ScoopInstaller/Java/master/bucket/zulu-jdk.json"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).architecture."64bit".url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\Morphe\jdk_windows-x64_bin.zip"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# Expand jdk_windows-x64_bin archive
$Parameters = @{
    Path            = "$CurrentFolder\Morphe\jdk_windows-x64_bin.zip"
    DestinationPath = "$CurrentFolder\Morphe\jdk"
    Force           = $true
    Verbose         = $true
}
Expand-Archive @Parameters

Remove-Item -Path "$CurrentFolder\Morphe\jdk_windows-x64_bin.zip" -Force

# Find latest supported YouTube APK version
Write-Verbose -Message "" -Verbose
Write-Verbose -Message "Getting latest supported YouTube APK version" -Verbose
$patches_list = & "$CurrentFolder\Morphe\jdk\zulu*win_x64\bin\java.exe" `
-jar "$CurrentFolder\Morphe\morphe-cli.jar" list-patches `
--with-packages `
--with-versions `
-f "com.google.android.youtube" `
"$CurrentFolder\Morphe\morphe-patches.mpp"
$LatestSupported = [regex]::Matches($patches_list, "\d{2}\.\d{2}\.\d{2}") | ForEach-Object { $_.Value } | Sort-Object -Descending -Unique | Select-Object -First 1
Write-Host "Download: https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupported.replace('.', '-'))-release/" -ForegroundColor Green
Write-Host "Place the file in the 'Morphe' folder with the name 'youtube.apk'." -ForegroundColor Green
Write-Host "Press Enter to continue." -ForegroundColor Green
Read-Host

# Let's create patched APK
& "$CurrentFolder\Morphe\jdk\zulu*win_x64\bin\java.exe" `
-jar "$CurrentFolder\Morphe\morphe-cli.jar" patch `
--patches "$CurrentFolder\Morphe\morphe-patches.mpp" `
--disable "Alternative thumbnails" `
--disable "Custom branding" `
--disable "Change header" `
--disable "Shorts autoplay" `
--disable "Theme" `
--purge `
--temporary-files-path "$CurrentFolder\Morphe\Temp" `
--out "$CurrentFolder\Morphe\morphe.apk" `
"$CurrentFolder\Morphe\youtube.apk"

# Open working directory with builded files
# Invoke-Item -Path "$CurrentFolder\Morphe"

$Files = @(
    "$CurrentFolder\Morphe\Temp",
    "$CurrentFolder\Morphe\jdk",
    "$CurrentFolder\Morphe\morphe-cli.jar",
    "$CurrentFolder\Morphe\morphe-patches.mpp",
    "$CurrentFolder\Morphe\youtube.apk"
)
Remove-Item -Path $Files -Recurse -Force

Write-Warning -Message "Latest available morphe.apk & microg.apk are ready in `"$CurrentFolder\Morphe`""

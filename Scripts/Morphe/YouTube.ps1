# Get the latest supported YouTube version to patch
$JavaPath = (Resolve-Path -Path "Morphe\jdk_windows-x64_bin\zulu*win_x64\bin\java.exe").Path
$patches_list = & $JavaPath `
-jar "Morphe\morphe-cli.jar" list-patches `
--patches "Morphe\morphe-patches.mpp" `
--with-packages `
--with-versions `
--filter-package-name "com.google.android.youtube"
$LatestSupported = [regex]::Matches($patches_list, "\d{2}\.\d{2}\.\d{2,3}") | ForEach-Object { $_.Value } | Sort-Object -Descending -Unique | Select-Object -First 1
$LatestSupportedYT = $LatestSupported.Replace('.', '-')

Get-Process -Name msedgedriver, msedge -ErrorAction Ignore | Stop-Process -Force -ErrorAction Ignore

Write-Verbose -Message "Microsoft Edge driver" -Verbose

# Get runner Microsoft Edge Version
# https://edgeupdates.microsoft.com/api/products
# https://github.com/GoogleChromeLabs/chrome-for-testing/blob/main/data/last-known-good-versions-with-downloads.json
$RunnerEdgeVersion = (Get-Item -Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe").VersionInfo.FileVersion

# Download Microsoft Edge driver
# https://developer.microsoft.com/microsoft-edge/tools/webdriver/
$Parameters = @{
    Uri             = "https://msedgedriver.microsoft.com/$RunnerEdgeVersion/edgedriver_win64.zip"
    OutFile         = "Morphe\edgedriver_win64.zip"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-Webrequest @Parameters

Write-Verbose -Message "Selenium web driver" -Verbose

# Download Selenium web driver
# https://www.nuget.org/packages/selenium.webdriver
# https://www.nuget.org/packages/selenium.support
try
{
    $Parameters = @{
        Uri             = "https://www.nuget.org/api/v2/package/Selenium.WebDriver"
        OutFile         = "Morphe\selenium.webdriver.nupkg"
        UseBasicParsing = $true
        Verbose         = $true
        ErrorAction     = "Stop"
    }
    Invoke-RestMethod @Parameters
}
catch
{
    Write-Verbose -Message "Cannot download Selenium web driver" -Verbose

    # Exit with a non-zero status to fail the job
    exit 1
}

$Parameters = @{
    Path            = "Morphe\edgedriver_win64.zip"
    DestinationPath = "Morphe"
    Force           = $true
    Verbose         = $true
}
Expand-Archive @Parameters

# Extract WebDriver.dll from archive
Add-Type -Assembly System.IO.Compression.FileSystem
$ZIP = [IO.Compression.ZipFile]::OpenRead("Morphe\selenium.webdriver.nupkg")
$Entries = $ZIP.Entries | Where-Object -FilterScript {$_.FullName -eq "lib/net8.0/WebDriver.dll"}
$Entries | ForEach-Object -Process {[IO.Compression.ZipFileExtensions]::ExtractToFile($_, "Morphe\$($_.Name)", $true)}
$ZIP.Dispose()

$Paths = @(
    "Morphe\Driver_Notes",
    "Morphe\edgedriver_win64.zip",
    "Morphe\selenium.webdriver.nupkg"
)
Remove-Item -Path $Paths -Force -Recurse

Write-Verbose -Message "Adding web driver" -Verbose

# Start parsing page
Add-Type -Path "Morphe\WebDriver.dll"

$Options = New-Object -TypeName OpenQA.Selenium.Edge.EdgeOptions
$Options.AddArgument("--headless=new")
$Options.AddArgument("--window-size=1280,720")
$Options.AddArgument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0")
$driver = New-Object -TypeName OpenQA.Selenium.Edge.EdgeDriver("Morphe\msedgedriver.exe", $Options)

# https://www.apkmirror.com/apk/google-inc/youtube/
# Get right youtube link
$links = @(
    "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-android-apk-download/",
    "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-1-android-apk-download/",
    "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-2-android-apk-download/",
    "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-3-android-apk-download/"
    "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-4-android-apk-download/"
)
$DownloadURL = $null

foreach ($link in $links) {
    Write-Verbose -Message "Trying URL $link" -Verbose
    $driver.Navigate().GoToUrl($link)
    $ButtonTitle = $driver.FindElement([OpenQA.Selenium.By]::CssSelector("a.downloadButton"))
    $ButtonTitle.Text.Trim()
    if (($ButtonTitle.Text.Trim() -match "(?i)download apk") -and ($ButtonTitle.Text.Trim() -notmatch "(?i)bundle"))
    {
        Write-Verbose -Message "Found 'DOWNLOAD APK' on $link" -Verbose
        $DownloadURL = $ButtonTitle.GetAttribute("href")
        break
    }
    Start-Sleep -Seconds 5
}

if ([string]::IsNullOrWhiteSpace($DownloadURL)) {
    Write-Verbose -Message "No link with 'DOWNLOAD APK' found. Exiting." -Verbose
    $driver.Quit()
    exit
}

# Download youtube.apk
# Waiting for Edge to finish downloading
$driver.Navigate().GoToUrl($DownloadURL)

# Get runned Downloads folder
$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"

# Wait until apk is being downloaded
do
{
    $APK = Test-Path -Path "$DownloadsFolder\*.apk"
    if (-not $APK)
    {
        "Waiting for an APK file to be downloaded..."
        Start-Sleep -Seconds 5
    }
}
while (-not $APK)

# Copy APK to Morphe folder
$Parameters = @{
    Path        = "$DownloadsFolder\*.apk"
    Destination = "Morphe"
    Force       = $true
}
Copy-Item @Parameters

# Rename file to youtube.apk
Get-Item -Path "Morphe\com.google.android*.apk" | Rename-Item -NewName youtube.apk -Force

$driver.Quit()
Get-Process -Name msedgedriver, msedge -ErrorAction Ignore | Stop-Process -Force -ErrorAction Ignore

echo "SupportedYoutube=$LatestSupported" >> $env:GITHUB_OUTPUT

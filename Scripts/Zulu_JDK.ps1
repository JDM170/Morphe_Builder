# https://github.com/ScoopInstaller/Java/blob/master/bucket/zulu-jdk.json
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/ScoopInstaller/Java/master/bucket/zulu-jdk.json"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = $apiResult.architecture."64bit".url
$TAG = $apiResult.version
$Parameters = @{
    Uri             = $URL
    Outfile         = "Morphe\jdk_windows-x64_bin.zip"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "ZuluTag=$TAG" >> $env:GITHUB_ENV

Write-Verbose -Message "Expanding Zulu JDK" -Verbose

$Parameters = @{
    Path            = "Morphe\jdk_windows-x64_bin.zip"
    DestinationPath = "Morphe\jdk_windows-x64_bin"
    Force           = $true
    Verbose         = $true
}
Expand-Archive @Parameters

Remove-Item -Path "Morphe\jdk_windows-x64_bin.zip" -Force

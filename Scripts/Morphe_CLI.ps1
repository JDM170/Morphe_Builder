# https://github.com/MorpheApp/morphe-cli
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/morphe-cli/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = ($apiResult.assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url | Select-Object -First 1
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Temp\morphe-cli.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "CLIvtag=$TAG" >> $env:GITHUB_ENV

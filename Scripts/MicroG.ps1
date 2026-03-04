# https://github.com/MorpheApp/MicroG-RE
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/MicroG-RE/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = ($apiResult.assets | Where-Object -FilterScript {$_.content_type -eq "application/vnd.android.package-archive"}).browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Morphe\microg.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "MicroGTag=$TAG" >> $env:GITHUB_ENV

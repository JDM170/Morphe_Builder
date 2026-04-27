# https://github.com/MorpheApp/morphe-patches
$Parameters = @{
    Uri             = "https://api.github.com/repos/MorpheApp/morphe-patches/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
    Headers         = @{
        Authorization = "token $env:GITHUB_TOKEN"
    }
}
$apiResult = Invoke-RestMethod @Parameters
$URL = ($apiResult.assets | Where-Object -FilterScript {$_.content_type -eq "application/dash-patch+xml"}).browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Morphe\morphe-patches.mpp"
    UseBasicParsing = $true
    Verbose         = $true
    Headers         = @{
        Authorization = "token $env:GITHUB_TOKEN"
    }
}
Invoke-RestMethod @Parameters

echo "Patchesvtag=$TAG" >> $env:GITHUB_OUTPUT

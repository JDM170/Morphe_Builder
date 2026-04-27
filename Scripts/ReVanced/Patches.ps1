# https://github.com/revanced/revanced-patches
$Parameters = @{
    Uri             = "https://api.revanced.app/v5/patches"
    UseBasicParsing = $true
    Verbose         = $true
    Headers         = @{
        Authorization = "token $env:GITHUB_TOKEN"
    }
}
$apiResult = Invoke-RestMethod @Parameters
$URL = $apiResult.download_url
$TAG = $apiResult.version
$Parameters = @{
    Uri             = $URL
    Outfile         = "ReVanced\revanced-patches.rvp"
    UseBasicParsing = $true
    Verbose         = $true
    Headers         = @{
        Authorization = "token $env:GITHUB_TOKEN"
    }
}
Invoke-RestMethod @Parameters

echo "Patchesvtag=$TAG" >> $env:GITHUB_OUTPUT

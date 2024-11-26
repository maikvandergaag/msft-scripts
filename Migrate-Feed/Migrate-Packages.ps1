param (
    [string]$organization,
    [string]$project,
    [string]$sourceFeed,
    [string]$destinationFeed,
    [string]$localFolder,
    [string]$pat
)

# Base64 encode the PAT
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Function to get packages from a feed
function Get-Packages {
    param (
        [string]$feed
    )
    $url = "https://feeds.dev.azure.com/$organization/$project/_apis/packaging/feeds/$feed/packages?api-version=6.0-preview.1&includeAllVersions=true"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    return $response.value
}

# Function to download all package files including their versions from a feed
function Get-PackagesFiles {
    param (
        [string]$feed,
        [string]$destinationFolder
    )

    $feedUri = "https://pkgs.dev.azure.com/$organization/$project/_packaging/$feed/pypi/simple/"
    $packages = Get-Packages -feed $feed

    foreach ($package in $packages) {
        foreach ($version in $package.versions) {
            $packageName = $package.normalizedName

            Write-Host "Downloading package: $packageName==$($version.version)" -ForegroundColor Green
            pip download "$packageName==$($version.version)" --no-deps --dest $destinationFolder --ignore-requires-python --index-url $feedUri
        }
    }
}

# Function to publish packages using twine
function Publish-Packages {
    param (
        [string]$sourceFolder,
        [string]$destination
    )

    $feed = "https://pkgs.dev.azure.com/$organization/_packaging/$destination/pypi/upload/"

    $twinePath = "twine"  # Ensure twine is installed and available in the PATH

    $packageFiles = Get-ChildItem -Path $sourceFolder

    foreach ($packageFile in $packageFiles) {
        $filePath = $packageFile.FullName

        Write-host "Publishing $filePath to $feed"
        & $twinePath upload --repository-url $feed -u x -p $pat $filePath 
    }
}

# Main script execution
Get-PackagesFiles -feed $sourceFeed -destinationFolder $localFolder
Publish-Packages -sourceFolder $localFolder -destination $destinationFeed

Write-Output "Packages have been successfully copied to the destination feed."
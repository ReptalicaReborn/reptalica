# convert_webp.ps1
# This script converts PNG images to WebP format for better web performance.
# It requires either ImageMagick (magick), Google libwebp (cwebp), or FFmpeg (ffmpeg) to be installed.

param (
    [string]$Folder = "assets/thumbnails",
    [int]$Quality = 80,
    [switch]$Recursive = $false,
    [switch]$Overwrite = $false
)

# Search for tools
$toolSource = $null

# Safety check: Prevent running on original folder
if ($Folder -like "*assets/original*") {
    Write-Host "Safety Error: This script is restricted from modifying the 'assets/original' folder to protect your source files." -ForegroundColor Yellow
    exit 1
}

if (Get-Command magick -ErrorAction SilentlyContinue) { $toolSource = "magick" }
elseif (Test-Path "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe") { $toolSource = "& 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'" }
elseif (Get-ChildItem -Path "C:\Program Files\ImageMagick*" -Filter "magick.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) { 
    $imPath = (Get-ChildItem -Path "C:\Program Files\ImageMagick*" -Filter "magick.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    $toolSource = "& '$imPath'" 
}
elseif (Get-Command cwebp -ErrorAction SilentlyContinue) { $toolSource = "cwebp" }
elseif (Get-Command ffmpeg -ErrorAction SilentlyContinue) { $toolSource = "ffmpeg" }

if (!$toolSource) {
    Write-Host "Error: No conversion tool (ImageMagick, cwebp, or FFmpeg) found in PATH or common install locations." -ForegroundColor Red
    Write-Host "Please install one of these tools to use this script."
    exit 1
}

Write-Host "Using tool: $toolSource" -ForegroundColor Green

$files = if ($Recursive) { Get-ChildItem -Path $Folder -Filter *.png -Recurse } else { Get-ChildItem -Path $Folder -Filter *.png }

if (!$files) {
    Write-Host "No PNG files found in $Folder."
    exit 0
}

$count = 0
foreach ($file in $files) {
    $destFile = [System.IO.Path]::ChangeExtension($file.FullName, ".webp")
    
    if (Test-Path $destFile) {
        if (!$Overwrite) {
            Write-Host "Skipping $($file.Name) (WebP already exists). Use -Overwrite to force." -ForegroundColor Gray
            continue
        }
    }

    Write-Host "Converting: $($file.Name) -> $([System.IO.Path]::GetFileName($destFile))"
    
    try {
        if ($toolSource -like "*magick*") {
            Invoke-Expression "$toolSource convert '$($file.FullName)' -quality $Quality '$destFile'"
        }
        elseif ($toolSource -eq "cwebp") {
            & cwebp -q $Quality $file.FullName -o $destFile
        }
        elseif ($toolSource -eq "ffmpeg") {
            & ffmpeg -i $file.FullName -q:v $Quality -y $destFile
        }
        $count++
    }
    catch {
        Write-Host "Failed to convert $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "Successfully converted $count files." -ForegroundColor Green

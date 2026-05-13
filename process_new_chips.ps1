Add-Type -AssemblyName System.Drawing

$srcFolder   = "assets/original"
$thumbFolder = "assets/thumbnails"
$optFolder   = "assets/optimized"

$newFiles = @(
    "Helio_G99.png",
    "Moore_Thread_SD102.png",
    "Nvida_Orin.png",
    "Phytium_Tengrui_D3000.jpg",
    "Spacemit_K1.png",
    "Intel_Arrow_Lake_S.png"
)

# Find magick
$magick = $null
if (Get-Command magick -ErrorAction SilentlyContinue) {
    $magick = "magick"
} elseif (Test-Path "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe") {
    $magick = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
} else {
    $found = Get-ChildItem -Path "C:\Program Files\ImageMagick*" -Filter "magick.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $magick = $found.FullName }
}

Write-Host "magick: $magick"

function Convert-ToWebP {
    param($srcPng, $destWebp)
    if ($magick) {
        & $magick convert $srcPng -quality 80 $destWebp
    } elseif (Get-Command cwebp -ErrorAction SilentlyContinue) {
        & cwebp -q 80 $srcPng -o $destWebp
    } elseif (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        & ffmpeg -i $srcPng -q:v 80 -y $destWebp
    } else {
        Write-Warning "No WebP conversion tool found."
    }
}

function Resize-And-Save {
    param($srcPath, $destPngPath, $targetWidth)
    $img = [System.Drawing.Image]::FromFile($srcPath)
    if ($img.Width -gt $targetWidth) {
        $scale  = $targetWidth / $img.Width
        $newH   = [int]($img.Height * $scale)
        $bmp    = New-Object System.Drawing.Bitmap $targetWidth, $newH
        $g      = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($img, 0, 0, $targetWidth, $newH)
        $bmp.Save($destPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $bmp.Dispose()
        Write-Host "  Resized: $($img.Width)x$($img.Height) -> ${targetWidth}x${newH}"
    } else {
        # Save as PNG regardless (handles .jpg source)
        $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height
        $g   = [System.Drawing.Graphics]::FromImage($bmp)
        $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
        $bmp.Save($destPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $bmp.Dispose()
        Write-Host "  Copied/converted to PNG (already <= ${targetWidth}px)"
    }
    $img.Dispose()
}

foreach ($name in $newFiles) {
    $src = Join-Path $srcFolder $name
    if (!(Test-Path $src)) {
        Write-Warning "Not found: $src"
        continue
    }

    $stem = [System.IO.Path]::GetFileNameWithoutExtension($name)
    Write-Host ""
    Write-Host "--- $name ---"

    # Thumbnail (400px)
    $thumbPng  = Join-Path $thumbFolder "$stem.png"
    $thumbWebp = Join-Path $thumbFolder "$stem.webp"

    if (Test-Path $thumbWebp) {
        Write-Host "  Thumbnail WebP already exists, skipping."
    } else {
        Resize-And-Save $src $thumbPng 400
        Convert-ToWebP $thumbPng $thumbWebp
        if (Test-Path $thumbWebp) { Write-Host "  Thumbnail WebP: OK" } else { Write-Host "  Thumbnail WebP: FAILED" }
    }

    # Optimized (800px)
    $optPng  = Join-Path $optFolder "$stem.png"
    $optWebp = Join-Path $optFolder "$stem.webp"

    if (Test-Path $optWebp) {
        Write-Host "  Optimized WebP already exists, skipping."
    } else {
        Resize-And-Save $src $optPng 800
        Convert-ToWebP $optPng $optWebp
        if (Test-Path $optWebp) { Write-Host "  Optimized WebP: OK" } else { Write-Host "  Optimized WebP: FAILED" }
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green

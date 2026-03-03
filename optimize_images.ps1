Add-Type -AssemblyName System.Drawing

$srcFolder = "assets/original"
$destFolder = "assets/optimized"
if (!(Test-Path $destFolder)) {
    New-Item -ItemType Directory -Force -Path $destFolder | Out-Null
}

$files = Get-ChildItem "$srcFolder\*.png"
$totalSaved = 0

foreach ($file in $files) {
    Write-Host "Processing $($file.Name)..."
    try {
        $img = [System.Drawing.Image]::FromFile($file.FullName)
        
        # Target width 800px (good for grid + reasonable modal)
        $targetWidth = 800
        
        if ($img.Width -gt $targetWidth) {
            $scale = $targetWidth / $img.Width
            $newHeight = [int]($img.Height * $scale)
            
            $newImg = new-object System.Drawing.Bitmap $targetWidth, $newHeight
            $graph = [System.Drawing.Graphics]::FromImage($newImg)
            $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graph.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            
            $graph.DrawImage($img, 0, 0, $targetWidth, $newHeight)
            
            $newPath = Join-Path $destFolder $file.Name
            
            # Save as PNG
            $newImg.Save($newPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            $graph.Dispose()
            $newImg.Dispose()
            
            # Try to convert to WebP if tools are available
            $webpPath = [System.IO.Path]::ChangeExtension($newPath, ".webp")
            $imFallback = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
            
            if (Get-Command magick -ErrorAction SilentlyContinue) {
                & magick convert $newPath -quality 80 $webpPath
            }
            elseif (Test-Path $imFallback) {
                & $imFallback convert $newPath -quality 80 $webpPath
            }
            elseif (Get-Command cwebp -ErrorAction SilentlyContinue) {
                & cwebp -q 80 $newPath -o $webpPath
            }
            elseif (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
                & ffmpeg -i $newPath -q:v 80 -y $webpPath
            }

            $oldSize = $file.Length
            $newSize = (Get-Item $newPath).Length
            $saved = $oldSize - $newSize
            $totalSaved += $saved
            
            Write-Host "  Resized: $($img.Width) -> $targetWidth"
            Write-Host "  Saved: $([math]::round($saved/1MB, 2)) MB"
            if (Test-Path $webpPath) { Write-Host "  WebP version created." }
        }
        else {
            Write-Host "  Skipping (already small enough)"
            Copy-Item $file.FullName $destFolder
            
            # Try to convert to WebP even if skipped resize
            $newPath = Join-Path $destFolder $file.Name
            $webpPath = [System.IO.Path]::ChangeExtension($newPath, ".webp")
            $imFallback = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
            
            if (Get-Command magick -ErrorAction SilentlyContinue) {
                & magick convert $newPath -quality 80 $webpPath
            }
            elseif (Test-Path $imFallback) {
                & $imFallback convert $newPath -quality 80 $webpPath
            }
            elseif (Get-Command cwebp -ErrorAction SilentlyContinue) {
                & cwebp -q 80 $newPath -o $webpPath
            }
            elseif (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
                & ffmpeg -i $newPath -q:v 80 -y $webpPath
            }
            if (Test-Path $webpPath) { Write-Host "  WebP version created." }
        }
        $img.Dispose()
    }
    catch {
        Write-Error "Failed to process $($file.Name): $_"
    }
}

Write-Host "Total space saved: $([math]::round($totalSaved/1MB, 2)) MB"

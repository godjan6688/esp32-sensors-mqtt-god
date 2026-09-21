Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = 'C:\Users\user\AppData\Local\Temp\codex-clipboard-ebe9a3af-79b0-4aae-93bb-33e6c1bdd40e.png'
$src = [System.Drawing.Bitmap]::new($srcPath)
$cloudRefPath = 'C:\Users\user\AppData\Local\Temp\codex-clipboard-c21ab302-3db6-4b51-aac7-d2583d2ea817.png'
$cloudRef = [System.Drawing.Bitmap]::new($cloudRefPath)

# Extract the actual cloud pixels from the supplied reference image. The
# contour and scrolls remain reference-derived; only the white background is
# removed by flood-filling from the crop boundary.
function ExtractReferenceCloud([System.Drawing.Bitmap]$image, [int]$left, [int]$top, [int]$width, [int]$height) {
    $art = [System.Drawing.Bitmap]::new($width, $height)
    $darkMap = New-Object 'bool[,]' $width,$height
    $sealedMap = New-Object 'bool[,]' $width,$height
    $outside = New-Object 'bool[,]' $width,$height
    $queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $p = $image.GetPixel($left + $x, $top + $y)
            $darkMap[$x,$y] = ($p.R -lt 220 -and $p.G -lt 220 -and $p.B -lt 220)
        }
    }
    # Close only tiny anti-aliased gaps so the reference cloud interior stays
    # white after background removal; the original dark pixels are preserved.
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if ($darkMap[$x,$y]) {
                for ($dy = -5; $dy -le 5; $dy++) {
                    for ($dx = -5; $dx -le 5; $dx++) {
                        $nx = $x + $dx; $ny = $y + $dy
                        if ($nx -ge 0 -and $nx -lt $width -and $ny -ge 0 -and $ny -lt $height) {
                            $sealedMap[$nx,$ny] = $true
                        }
                    }
                }
            }
        }
    }
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if (($x -eq 0 -or $y -eq 0 -or $x -eq ($width - 1) -or $y -eq ($height - 1)) -and -not $sealedMap[$x,$y]) {
                if (-not $outside[$x,$y]) {
                    $outside[$x,$y] = $true
                    $queue.Enqueue([System.Drawing.Point]::new($x,$y))
                }
            }
        }
    }
    while ($queue.Count -gt 0) {
        $pt = $queue.Dequeue()
        foreach ($n in @(
            [System.Drawing.Point]::new($pt.X + 1, $pt.Y),
            [System.Drawing.Point]::new($pt.X - 1, $pt.Y),
            [System.Drawing.Point]::new($pt.X, $pt.Y + 1),
            [System.Drawing.Point]::new($pt.X, $pt.Y - 1)
        )) {
            if ($n.X -ge 0 -and $n.X -lt $width -and $n.Y -ge 0 -and $n.Y -lt $height -and -not $outside[$n.X,$n.Y]) {
                if (-not $sealedMap[$n.X,$n.Y]) {
                    $outside[$n.X,$n.Y] = $true
                    $queue.Enqueue($n)
                }
            }
        }
    }
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            if ($darkMap[$x,$y]) {
                $art.SetPixel($x, $y, [System.Drawing.Color]::Black)
            } elseif ($outside[$x,$y]) {
                $art.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            } else {
                $art.SetPixel($x, $y, [System.Drawing.Color]::White)
            }
        }
    }
    return $art
}

$cloudUpper = ExtractReferenceCloud $cloudRef 90 5 255 140
$cloudLower = ExtractReferenceCloud $cloudRef 105 145 242 138

# Crop the original two rabbits and the mortar/pestle as one intact reference group.
$cropX = 65; $cropY = 90; $cropW = 250; $cropH = 220
$mask = [System.Drawing.Bitmap]::new($cropW, $cropH)
for ($y = 0; $y -lt $cropH; $y++) {
    for ($x = 0; $x -lt $cropW; $x++) {
        $p = $src.GetPixel($cropX + $x, $cropY + $y)
        if ($p.R -lt 85 -and $p.G -lt 85 -and $p.B -lt 85) {
            $mask.SetPixel($x, $y, [System.Drawing.Color]::Black)
        } else {
            $mask.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
        }
    }
}

$canvas = [System.Drawing.Bitmap]::new(296, 128)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::White)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$red = [System.Drawing.Color]::FromArgb(220, 0, 0)
$g.FillEllipse([System.Drawing.SolidBrush]::new($red), 3, 2, 126, 126)

# Scale the intact reference group into the red moon, with safe margins so neither rabbit is cut.
$dest = [System.Drawing.Rectangle]::new(7, 12, 120, 104)
$g.DrawImage($mask, $dest)

# Blessing panel.
$pen = [System.Drawing.Pen]::new($red, 2)
$g.DrawRectangle($pen, 149, 8, 138, 112)
$pen.Dispose()
$fontTop = [System.Drawing.Font]::new('Microsoft JhengHei', 7, [System.Drawing.FontStyle]::Regular)
$font1 = [System.Drawing.Font]::new('Microsoft JhengHei', 11, [System.Drawing.FontStyle]::Bold)
$font2 = [System.Drawing.Font]::new('Microsoft JhengHei', 9, [System.Drawing.FontStyle]::Regular)
$font3 = [System.Drawing.Font]::new('Microsoft JhengHei', 6, [System.Drawing.FontStyle]::Regular)
$brushBlack = [System.Drawing.Brushes]::Black
$brushRed = [System.Drawing.SolidBrush]::new($red)
function U([int[]]$codes) {
    return (-join ($codes | ForEach-Object { [char]$_ }))
}
$g.DrawString((U @(21214,21205,37096,39640,23631,28558,26481,20998,32626,25964,31069)), $fontTop, $brushBlack, 154, 13)
$centerFormat = [System.Drawing.StringFormat]::new()
$centerFormat.Alignment = [System.Drawing.StringAlignment]::Center
$centerFormat.LineAlignment = [System.Drawing.StringAlignment]::Near
$panelRect = [System.Drawing.RectangleF]::new(151, 27, 134, 22)
$g.DrawString((U @(20013,31179,31680,24555,27138)), $font1, $brushBlack, $panelRect, $centerFormat)
$panelRect = [System.Drawing.RectangleF]::new(151, 50, 134, 18)
$g.DrawString((U @(26376,22291,20154,22243,22291)), $font2, $brushRed, $panelRect, $centerFormat)
$panelRect = [System.Drawing.RectangleF]::new(151, 68, 134, 18)
$g.DrawString((U @(24184,31119,22909,20107,36899,36899)), $font2, $brushRed, $panelRect, $centerFormat)
$panelRect = [System.Drawing.RectangleF]::new(151, 96, 134, 13)
$g.DrawString('HAPPY MOON FESTIVAL', $font3, $brushBlack, $panelRect, $centerFormat)

# Directly use the two cloud motifs from the supplied reference image.
# Each placement has a margin from the 296x128 canvas boundary.
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($cloudUpper, [System.Drawing.Rectangle]::new(88, 3, 39, 23))
$g.DrawImage($cloudUpper, [System.Drawing.Rectangle]::new(4, 4, 36, 22))
$g.DrawImage($cloudUpper, [System.Drawing.Rectangle]::new(4, 93, 55, 25))
# The lower-right cloud previously used a source region too close to the
# reference image's lower edge. Use the complete upper reference motif here
# and keep it inset from the moon/canvas boundary.
$g.DrawImage($cloudUpper, [System.Drawing.Rectangle]::new(74, 78, 49, 25))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$centerFormat.Dispose()

$outPath = Join-Path $root 'moon_rabbit_direct_reference_slender_ears_v4.png'
$canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$canvas.Dispose()
$mask.Dispose()
$src.Dispose()
$cloudUpper.Dispose()
$cloudLower.Dispose()
$cloudRef.Dispose()
Write-Output $outPath

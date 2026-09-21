Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'moon_rabbit_direct_reference_slender_ears_v4.png'
$out = Join-Path $root 'moon_rabbit_improved.png'
$src = [System.Drawing.Bitmap]::new($source)
$w = 296
$h = 128
$bmp = [System.Drawing.Bitmap]::new($w,$h)
$black = [System.Drawing.Color]::FromArgb(17,17,17)
$red = [System.Drawing.Color]::FromArgb(215,25,32)
$white = [System.Drawing.Color]::White

# Reduce the source to exact panel colors.
for ($y=0; $y -lt $h; $y++) {
  for ($x=0; $x -lt $w; $x++) {
    $p = $src.GetPixel($x,$y)
    if (($p.R -lt 105) -and ($p.G -lt 105) -and ($p.B -lt 105)) { $c=$black }
    elseif (($p.R -gt 125) -and ($p.R -gt $p.G*1.35) -and ($p.R -gt $p.B*1.35)) { $c=$red }
    else { $c=$white }
    $bmp.SetPixel($x,$y,$c)
  }
}

# Remove isolated white pinholes in the black rabbit silhouettes only.
$clean = [System.Drawing.Bitmap]::new($bmp)
for ($y=1; $y -lt 127; $y++) {
  for ($x=1; $x -lt 145; $x++) {
    if ($bmp.GetPixel($x,$y).ToArgb() -ne $white.ToArgb()) { continue }
    $blackNeighbors = 0
    for ($dy=-1; $dy -le 1; $dy++) {
      for ($dx=-1; $dx -le 1; $dx++) {
        if ($dx -eq 0 -and $dy -eq 0) { continue }
        if ($bmp.GetPixel($x+$dx,$y+$dy).ToArgb() -eq $black.ToArgb()) { $blackNeighbors++ }
      }
    }
    if ($blackNeighbors -ge 5) { $clean.SetPixel($x,$y,$black) }
  }
}
$bmp.Dispose()
$bmp = $clean

# Clear and redraw the greeting area at a readable size.
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.FillRectangle([System.Drawing.Brushes]::White,145,0,151,128)
$penRed = [System.Drawing.Pen]::new($red,2)
$brushBlack = [System.Drawing.SolidBrush]::new($black)
$brushRed = [System.Drawing.SolidBrush]::new($red)
$g.DrawRectangle($penRed,149,7,142,114)
$g.DrawLine($penRed,153,21,287,21)
$g.DrawLine($penRed,153,101,287,101)
$fTop = [System.Drawing.Font]::new('Noto Sans TC',7,[System.Drawing.FontStyle]::Bold)
$fMain = [System.Drawing.Font]::new('Noto Sans TC',16,[System.Drawing.FontStyle]::Bold)
$fLine = [System.Drawing.Font]::new('Noto Sans TC',13,[System.Drawing.FontStyle]::Bold)
$fEng = [System.Drawing.Font]::new('Arial',7,[System.Drawing.FontStyle]::Bold)
$g.DrawString('勞動部高屏澎東分署敬祝',$fTop,$brushBlack,153,9)
$g.DrawString('中秋節快樂',$fMain,$brushBlack,162,27)
$g.DrawString('月圓人團圓',$fLine,$brushRed,164,54)
$g.DrawString('幸福好事連連',$fLine,$brushBlack,155,78)
$g.DrawString('HAPPY MOON FESTIVAL',$fEng,$brushBlack,169,106)
$g.Dispose()

# Quantize text antialiasing back to the three panel colors.
$final = [System.Drawing.Bitmap]::new($w,$h)
for ($y=0; $y -lt $h; $y++) {
  for ($x=0; $x -lt $w; $x++) {
    $p=$bmp.GetPixel($x,$y)
    if (($p.R -gt 125) -and ($p.R -gt $p.G*1.35) -and ($p.R -gt $p.B*1.35)) { $c=$red }
    elseif (($p.R+$p.G+$p.B) -lt 420) { $c=$black }
    else { $c=$white }
    $final.SetPixel($x,$y,$c)
  }
}
$final.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose(); $bmp.Dispose(); $src.Dispose()
Write-Output $out

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'sensor_dashboard_preview.png'
$scale = 4
$w = 296
$h = 128
$hi = [System.Drawing.Bitmap]::new($w*$scale,$h*$scale)
$g = [System.Drawing.Graphics]::FromImage($hi)
$g.ScaleTransform($scale,$scale)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$white = [System.Drawing.Color]::White
$black = [System.Drawing.Color]::FromArgb(15,15,15)
$red = [System.Drawing.Color]::FromArgb(210,25,32)
$gray = [System.Drawing.Color]::FromArgb(245,245,245)
$wb = [System.Drawing.SolidBrush]::new($white)
$bb = [System.Drawing.SolidBrush]::new($black)
$rb = [System.Drawing.SolidBrush]::new($red)
$gp = [System.Drawing.Pen]::new($black,1.4)
$rp = [System.Drawing.Pen]::new($red,2)
$g.Clear($white)

# Header
$g.DrawString('環境監測',[System.Drawing.Font]::new('Noto Sans TC',13,[System.Drawing.FontStyle]::Bold),$bb,8,3)
$g.DrawString('即時資料',[System.Drawing.Font]::new('Noto Sans TC',7,[System.Drawing.FontStyle]::Bold),$rb,235,8)
$g.DrawLine($rp,8,24,288,24)

# Three readable cards with one consistent layout
$xs = @(8,105,202)
$labels = @('溫度','濕度','亮度')
$values = @('25.6','60','320')
$units = @('°C','%RH','lx')
$labelFont = [System.Drawing.Font]::new('Noto Sans TC',9,[System.Drawing.FontStyle]::Bold)
$valueFont = [System.Drawing.Font]::new('Arial',18,[System.Drawing.FontStyle]::Bold)
$unitFont = [System.Drawing.Font]::new('Arial',8,[System.Drawing.FontStyle]::Bold)
for ($i=0; $i -lt 3; $i++) {
  $x=$xs[$i]
  $g.FillRectangle([System.Drawing.SolidBrush]::new($gray),$x,31,87,88)
  $g.DrawRectangle($gp,$x,31,87,88)
  $labelSize = $g.MeasureString($labels[$i],$labelFont)
  $valueSize = $g.MeasureString($values[$i],$valueFont)
  $g.DrawString($labels[$i],$labelFont,$bb,$x+(87-$labelSize.Width)/2,61)
  $g.DrawString($values[$i],$valueFont,$rb,$x+(87-$valueSize.Width)/2,78)
  # Every unit is anchored to the same lower-right position relative to the number.
  $g.DrawString($units[$i],$unitFont,$bb,$x+61,94)
}

# Consistent 24x24 icon boxes, all centered at y=38.
# Thermometer: black outline, red bulb and red column.
$g.DrawEllipse($gp,40,49,12,12)
$g.FillEllipse($rb,43,52,6,6)
$g.DrawLine($rp,46,49,46,38)
$g.DrawLine($gp,50,40,54,40); $g.DrawLine($gp,50,44,54,44); $g.DrawLine($gp,50,48,54,48)

# Droplet: simple closed red drop with black outline.
$drop = [System.Drawing.Drawing2D.GraphicsPath]::new()
$drop.AddBezier(132,38,125,47,125,56,132,59)
$drop.AddBezier(139,56,139,47,132,38,132,38)
$drop.CloseFigure()
$g.FillPath($rb,$drop); $g.DrawPath($gp,$drop); $drop.Dispose()

# Sun: red center with black outline and evenly spaced rays.
$g.FillEllipse($rb,226,46,14,14); $g.DrawEllipse($gp,226,46,14,14)
for ($a=0; $a -lt 8; $a++) {
  $angle = $a * [Math]::PI / 4
  $x1 = 233 + [Math]::Cos($angle)*11
  $y1 = 53 + [Math]::Sin($angle)*11
  $x2 = 233 + [Math]::Cos($angle)*16
  $y2 = 53 + [Math]::Sin($angle)*16
  $g.DrawLine($gp,[float]$x1,[float]$y1,[float]$x2,[float]$y2)
}

$g.Dispose()

# Quantize to exact white / black / red pixels for the tri-color panel.
$final = [System.Drawing.Bitmap]::new($w,$h)
for ($y=0; $y -lt $h; $y++) {
  for ($x=0; $x -lt $w; $x++) {
    $r=0; $gg=0; $b=0
    for ($sy=0; $sy -lt $scale; $sy++) {
      for ($sx=0; $sx -lt $scale; $sx++) {
        $p=$hi.GetPixel($x*$scale+$sx,$y*$scale+$sy)
        $r += $p.R; $gg += $p.G; $b += $p.B
      }
    }
    $r=[int]($r/16); $gg=[int]($gg/16); $b=[int]($b/16)
    if (($r -gt 125) -and ($r -gt $gg*1.35) -and ($r -gt $b*1.35)) { $c=$red }
    elseif (($r+$gg+$b) -lt 510) { $c=$black }
    else { $c=$white }
    $final.SetPixel($x,$y,$c)
  }
}
$final.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose(); $hi.Dispose()
Write-Output $out

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Common -ErrorAction SilentlyContinue

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'moon_rabbit_improved.png'
$scale = 4
$w = 296
$h = 128
$hi = [System.Drawing.Bitmap]::new($w * $scale, $h * $scale)
$g = [System.Drawing.Graphics]::FromImage($hi)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.ScaleTransform($scale, $scale)

$white = [System.Drawing.Color]::White
$black = [System.Drawing.Color]::FromArgb(17,17,17)
$red = [System.Drawing.Color]::FromArgb(215,25,32)
$bg = [System.Drawing.SolidBrush]::new($white)
$bk = [System.Drawing.SolidBrush]::new($black)
$rd = [System.Drawing.SolidBrush]::new($red)
$pen = [System.Drawing.Pen]::new($black, 2.2)
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.Clear($white)

# Moon
$g.FillEllipse($rd, 12, 8, 112, 112)

function Cloud([System.Drawing.Graphics]$graphics, [System.Drawing.Drawing2D.GraphicsPath]$path) {
    $graphics.FillPath($bg, $path)
    $graphics.DrawPath($pen, $path)
}

# Small, clean clouds; each is fully contained and does not cross the rabbits.
function SimpleCloud([System.Drawing.Graphics]$graphics, [int]$x, [int]$y, [int]$width, [int]$height) {
    $outline = [System.Drawing.Pen]::new($black, 1.8)
    $graphics.FillEllipse($bg, $x, $y + 5, [int]($width * 0.38), [int]($height * 0.55))
    $graphics.FillEllipse($bg, $x + [int]($width * 0.24), $y, [int]($width * 0.45), $height)
    $graphics.FillEllipse($bg, $x + [int]($width * 0.58), $y + 5, [int]($width * 0.38), [int]($height * 0.55))
    $graphics.FillRectangle($bg, $x + 4, $y + [int]($height * 0.45), $width - 8, [int]($height * 0.45))
    $graphics.DrawEllipse($outline, $x, $y + 5, [int]($width * 0.38), [int]($height * 0.55))
    $graphics.DrawEllipse($outline, $x + [int]($width * 0.24), $y, [int]($width * 0.45), $height)
    $graphics.DrawEllipse($outline, $x + [int]($width * 0.58), $y + 5, [int]($width * 0.38), [int]($height * 0.55))
    $graphics.DrawLine($outline, $x + 4, $y + [int]($height * 0.88), $x + $width - 4, $y + [int]($height * 0.88))
}
SimpleCloud $g 4 17 34 14
SimpleCloud $g 4 96 34 14
SimpleCloud $g 108 96 36 14

# Mortar
$m = [System.Drawing.Drawing2D.GraphicsPath]::new()
$m.AddBezier(39,85,58,80,84,80,103,84); $m.AddLine(99,108); $m.AddBezier(79,115,60,115,43,108,43,108); $m.CloseFigure()
$g.FillPath($bk, $m); $m.Dispose()
$g.FillEllipse($bg, 36,76,68,16); $g.DrawEllipse($pen,36,76,68,16)
$g.FillEllipse($rd,43,80,54,7)

# Standing rabbit, clearly lifting the pestle
$g.FillEllipse($bk,40,53,22,31); $g.FillEllipse($bk,42,39,19,19)
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(46,40),[System.Drawing.PointF]::new(40,25),[System.Drawing.PointF]::new(43,17),[System.Drawing.PointF]::new(52,41)))
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(54,40),[System.Drawing.PointF]::new(57,25),[System.Drawing.PointF]::new(64,21),[System.Drawing.PointF]::new(59,43)))
$g.DrawLine([System.Drawing.Pen]::new($black,5),43,62,35,43)
$g.DrawLine([System.Drawing.Pen]::new($black,5),58,61,65,43)
$g.DrawLine([System.Drawing.Pen]::new($black,5),35,43,61,24)
$g.FillEllipse($bk,58,19,10,10)
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(43,80),[System.Drawing.PointF]::new(39,101),[System.Drawing.PointF]::new(48,101),[System.Drawing.PointF]::new(52,81)))
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(53,80),[System.Drawing.PointF]::new(58,101),[System.Drawing.PointF]::new(67,101),[System.Drawing.PointF]::new(62,79)))
$g.FillEllipse($bk,61,60,9,9)

# Jumping rabbit, clearly bringing the pestle down
$g.FillEllipse($bk,81,40,23,29); $g.FillEllipse($bk,84,27,19,19)
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(88,29),[System.Drawing.PointF]::new(83,16),[System.Drawing.PointF]::new(86,9),[System.Drawing.PointF]::new(95,30)))
$g.FillPolygon($bk, @([System.Drawing.PointF]::new(96,30),[System.Drawing.PointF]::new(101,17),[System.Drawing.PointF]::new(108,13),[System.Drawing.PointF]::new(101,34)))
$g.DrawLine([System.Drawing.Pen]::new($black,5),85,62,69,72)
$g.DrawLine([System.Drawing.Pen]::new($black,5),99,64,116,70)
$g.FillEllipse($bk,64,68,9,9); $g.FillEllipse($bk,113,66,9,9)
$g.DrawLine([System.Drawing.Pen]::new($black,5),87,51,82,68)
$g.DrawLine([System.Drawing.Pen]::new($black,5),99,52,104,69)
$g.DrawLine([System.Drawing.Pen]::new($black,6),83,67,96,90)
$g.FillEllipse($bk,92,87,12,12)

# Motion marks
$motion = [System.Drawing.Pen]::new($black, 2.5)
$g.DrawLine($motion,76,27,82,20); $g.DrawLine($motion,80,33,89,25)
$g.DrawLine($motion,111,78,120,85); $g.DrawLine($motion,108,84,116,93)

# Text
$fontPath = 'C:\Windows\Fonts\NotoSansTC-VF.ttf'
$f1 = [System.Drawing.Font]::new('Noto Sans TC', 7.2, [System.Drawing.FontStyle]::Bold)
$f2 = [System.Drawing.Font]::new('Noto Sans TC', 17, [System.Drawing.FontStyle]::Bold)
$f3 = [System.Drawing.Font]::new('Noto Sans TC', 15, [System.Drawing.FontStyle]::Bold)
$f4 = [System.Drawing.Font]::new('Noto Sans TC', 14, [System.Drawing.FontStyle]::Bold)
$fa = [System.Drawing.Font]::new('Arial', 7.5, [System.Drawing.FontStyle]::Bold)
$g.DrawString('勞動部高屏澎東分署敬祝',$f1,$bk,153,5)
$g.FillRectangle($rd,153,19,138,2)
$g.DrawString('中秋節快樂',$f2,$bk,153,23)
$g.DrawString('月圓人團圓',$f3,$rd,153,49)
$g.DrawString('幸福好事連連',$f4,$bk,153,75)
$g.FillRectangle($rd,153,103,138,2)
$g.DrawString('HAPPY MOON FESTIVAL',$fa,$bk,153,106)

$g.Dispose()

# Downsample and quantize to exact white / black / red pixels.
$outBmp = [System.Drawing.Bitmap]::new($w,$h)
for ($y=0; $y -lt $h; $y++) {
  for ($x=0; $x -lt $w; $x++) {
    $r=0; $gg=0; $b=0
    for ($sy=0; $sy -lt $scale; $sy++) {
      for ($sx=0; $sx -lt $scale; $sx++) {
        $q=$hi.GetPixel($x*$scale+$sx,$y*$scale+$sy)
        $r += $q.R; $gg += $q.G; $b += $q.B
      }
    }
    $r=[int]($r/($scale*$scale)); $gg=[int]($gg/($scale*$scale)); $b=[int]($b/($scale*$scale))
    if (($r -gt 130) -and ($r -gt $gg*1.35) -and ($r -gt $b*1.35)) { $c=$red }
    elseif (($r+$gg+$b) -lt 420) { $c=$black }
    else { $c=$white }
    $outBmp.SetPixel($x,$y,$c)
  }
}
$outBmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$outBmp.Dispose(); $hi.Dispose()
Write-Output $out

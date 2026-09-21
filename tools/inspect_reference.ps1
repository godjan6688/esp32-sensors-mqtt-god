Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile('C:\Users\user\AppData\Local\Temp\codex-clipboard-ebe9a3af-79b0-4aae-93bb-33e6c1bdd40e.png')
$out = New-Object System.Drawing.Bitmap 758,758
$g = [System.Drawing.Graphics]::FromImage($out)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($src, 0, 0, 758, 758)
$g.Dispose()
$out.Save((Join-Path $PSScriptRoot '..\reference_upscale.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
$src.Dispose()

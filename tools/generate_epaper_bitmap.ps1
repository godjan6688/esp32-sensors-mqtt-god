Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$imagePath = Join-Path $root 'moon_rabbit_improved.png'
$outPath = Join-Path $root 'examples\ESP32_2in9b_V4\moon_rabbit_bitmap.h'
$image = [System.Drawing.Bitmap]::new($imagePath)

if ($image.Width -ne 296 -or $image.Height -ne 128) {
    throw "Expected 296x128 preview, got $($image.Width)x$($image.Height)"
}

function MakeMask([System.Drawing.Bitmap]$bitmap, [string]$kind) {
    $bytes = [System.Collections.Generic.List[byte]]::new()
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($byteX = 0; $byteX -lt $bitmap.Width; $byteX += 8) {
            [byte]$value = 0
            for ($bit = 0; $bit -lt 8; $bit++) {
                $x = $byteX + $bit
                if ($x -ge $bitmap.Width) { continue }
                $p = $bitmap.GetPixel($x, $y)
                $isSet = $false
                if ($kind -eq 'black') {
                    $isSet = ($p.R -lt 100 -and $p.G -lt 100 -and $p.B -lt 100)
                } else {
                    $isSet = ($p.R -gt 120 -and $p.G -lt 100 -and $p.B -lt 100)
                }
                if ($isSet) {
                    $value = $value -bor (1 -shl (7 - $bit))
                }
            }
            $bytes.Add($value)
        }
    }
    return $bytes
}

function FormatBytes([System.Collections.Generic.List[byte]]$bytes) {
    $lines = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $bytes.Count; $i += 16) {
        $end = [Math]::Min($i + 16, $bytes.Count)
        $part = for ($j = $i; $j -lt $end; $j++) { '0x{0:X2}' -f $bytes[$j] }
        $lines.Add('  ' + ($part -join ', ') + ',')
    }
    return ($lines -join "`r`n")
}

$black = MakeMask $image 'black'
$red = MakeMask $image 'red'
$header = @"
#pragma once
#include <Arduino.h>

// Generated from moon_rabbit_improved.png (296x128).
// Each mask is 1 bit per pixel, row-major, MSB first.
const uint8_t moon_rabbit_black[] PROGMEM = {
$(FormatBytes $black)
};

const uint8_t moon_rabbit_red[] PROGMEM = {
$(FormatBytes $red)
};
"@

[System.IO.File]::WriteAllText($outPath, $header, [System.Text.UTF8Encoding]::new($false))
$image.Dispose()
Write-Output $outPath

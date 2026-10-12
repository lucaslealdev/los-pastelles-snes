# Renderizacao de contingencia para a etiqueta classica quando Python/Pillow nao
# estiver instalado. A fonte definitiva continua em cartucho.py.
param(
  [string]$Etiqueta = (Join-Path $PSScriptRoot '..\cartucho\etiqueta_formato_classico.png')
)

Add-Type -AssemblyName System.Drawing
$path = [IO.Path]::GetFullPath($Etiqueta)
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$out = New-Object Drawing.Bitmap 2400, 1320
$out.SetResolution(800, 800)
$g = [Drawing.Graphics]::FromImage($out)
$g.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias

function Brush([string]$hex) { New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml($hex)) }
function Font([string]$name, [float]$size, [Drawing.FontStyle]$style = [Drawing.FontStyle]::Regular) { [System.Drawing.Font]::new($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel) }
function Text([string]$value, [int]$x, [int]$y, [float]$size, [string]$color, [bool]$bold = $false) {
  $style = if ($bold) { [Drawing.FontStyle]::Bold } else { [Drawing.FontStyle]::Regular }
  $f = Font 'Arial' $size $style; $b = Brush $color
  $g.DrawString($value, $f, $b, $x, $y); $g.Flush(); $f.Dispose(); $b.Dispose()
}

# Tudo esta em 3x porque a imagem classica tem 2400 x 1320 pixels.
$s = 3
$black = Brush '#050505'; $red = Brush '#E00000'; $white = Brush '#FFFFFF'
$orange = Brush '#FAA61E'; $brown = Brush '#3A1A0C'
$g.Clear([Drawing.ColorTranslator]::FromHtml('#050505'))
# Frente principal: logo, foto real do jogo e acabamento em laranja/marrom.
$g.FillRectangle($orange, 128*$s, 22*$s, 420*$s, 396*$s)
$logoPath = Get-ChildItem -LiteralPath $root -Filter '*Pastelles*.png' | Select-Object -First 1 -ExpandProperty FullName
$logo = [Drawing.Bitmap]::FromFile($logoPath)
$bg = $logo.GetPixel(5,5)
for ($yy = 0; $yy -lt $logo.Height; $yy++) {
  for ($xx = 0; $xx -lt $logo.Width; $xx++) {
    $px = $logo.GetPixel($xx,$yy)
    if (([math]::Abs($px.R-$bg.R) + [math]::Abs($px.G-$bg.G) + [math]::Abs($px.B-$bg.B)) -lt 55) {
      $logo.SetPixel($xx,$yy,[Drawing.Color]::FromArgb(0,$px.R,$px.G,$px.B))
    }
  }
}
$g.DrawImage($logo, 138*$s, 38*$s, 285*$s, 260*$s); $logo.Dispose()
$photo = [Drawing.Image]::FromFile((Join-Path $root 'cartucho\fotos\foto_jogo.png'))
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.DrawImage($photo, 316*$s, 238*$s, 220*$s, 150*$s); $photo.Dispose()
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.FillRectangle($brown, 128*$s, 388*$s, 420*$s, 30*$s)
Text '1 JOGADOR' (140*$s) (343*$s) (15*$s) '#3A1A0C' $true
Text 'SALVA O JOGO NO CARTUCHO' (140*$s) (365*$s) (10*$s) '#3A1A0C' $true
$titleFont = [System.Drawing.Font]::new('Arial', 20*$s, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$titleBrush = Brush '#FAA61E'; $fmt = New-Object Drawing.StringFormat; $fmt.Alignment = [Drawing.StringAlignment]::Center
$g.DrawString('O IMPERIO DO PASTEL', $titleFont, $titleBrush, 338*$s, 388*$s, $fmt)
$g.Flush()
$titleFont.Dispose(); $titleBrush.Dispose(); $fmt.Dispose()
# Coluna da esquerda: identificacao independente e selo da marca.
Text 'UMA PRODUCAO' (24*$s) (78*$s) (10*$s) '#FFFFFF' $true
$g.FillRectangle($red, 20*$s, 94*$s, 92*$s, 24*$s)
Text 'LOS PASTELLES' (28*$s) (99*$s) (9*$s) '#FFFFFF' $true
$sealBrush = Brush '#C9A55C'; $g.FillEllipse($sealBrush, (28*$s),(312*$s),(76*$s),(76*$s)); $sealBrush.Dispose()
Text 'SELO DE' (43*$s) (332*$s) (7*$s) '#5A3A10' $true
Text 'QUALIDADE' (35*$s) (344*$s) (7*$s) '#5A3A10' $true
Text 'LOS PASTELLES' (31*$s) (357*$s) (6*$s) '#5A3A10' $true
Text 'LP-SNES-BRA' (20*$s) (392*$s) (11*$s) '#FFFFFF' $true
Text 'FEITO NO BRASIL' (20*$s) (406*$s) (11*$s) '#FFFFFF' $true
$g.FillRectangle($black, 550*$s, 66*$s, 250*$s, 374*$s)
$g.FillRectangle($red, 557*$s, 66*$s, 210*$s, 16*$s)
Text 'A COZINHA NAO PARA!' (558*$s) (94*$s) (11*$s) '#FFFFFF' $true
Text 'Transforme uma pequena' (558*$s) (112*$s) (8*$s) '#D8D8D8'
Text 'pastelaria no imperio' (558*$s) (124*$s) (8*$s) '#D8D8D8'
Text 'mais crocante da cidade.' (558*$s) (136*$s) (8*$s) '#D8D8D8'
$items = @(@('ATENDA','clientes e venca o relogio'),@('COZINHE','pasteis no ponto certo'),@('CRESCA','sua loja pelo bairro'),@('SALVE','sua jornada no cartucho'))
for ($i = 0; $i -lt $items.Count; $i++) {
  $y = (158 + $i*35)*$s
  $g.FillEllipse($orange, 558*$s, $y, 12*$s, 12*$s)
  Text ([string]($i+1)) (561*$s) ($y-2*$s) (7*$s) '#3A1A0C' $true
  Text $items[$i][0] (576*$s) ($y-2*$s) (8*$s) '#FFFFFF' $true
  Text $items[$i][1] (576*$s) ($y+9*$s) (7*$s) '#BDBDBD'
}
$widths = 2,1,3,1,1,2,4,1,2,1,3,2,1,4,1,2,3,1,2,4,1,1,3,2; $x=558*$s
for ($i = 0; $i -lt $widths.Count; $i++) { $w=$widths[$i]*$s; if ($i % 2 -eq 0) { $g.FillRectangle($white,$x,307*$s,$w,30*$s) }; $x += $w+$s }
Text '789  LOS  2026  016' (574*$s) (339*$s) (6*$s) '#BDBDBD'
Text 'PARA' (560*$s) (352*$s) (14*$s) '#E00000' $true
$consoleFont = [System.Drawing.Font]::new('Impact', 26*$s, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$consoleBrush = Brush '#E00000'
$g.DrawString('SUPER NINTENDO', $consoleFont, $consoleBrush, 556*$s, 366*$s)
$g.Flush()
$consoleFont.Dispose(); $consoleBrush.Dispose()

$g.Dispose(); $black.Dispose(); $red.Dispose(); $white.Dispose(); $orange.Dispose(); $brown.Dispose()
$out.Save($path, [Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
Write-Output "Etiqueta atualizada: $path"

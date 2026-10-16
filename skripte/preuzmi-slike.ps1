# Preuzima sve slike sa menijepomoglo.rs u assets\img\ i prebacuje HTML na lokalne putanje.
# Pokretanje (PowerShell, iz glavnog foldera sajta):
#   powershell -ExecutionPolicy Bypass -File skripte\preuzmi-slike.ps1
# Bezbedno je pokrenuti vise puta. Ako i jedna slika ne uspe, HTML se ne menja.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$root  = Split-Path -Parent $PSScriptRoot
$base  = 'https://www.menijepomoglo.rs/wp-content/uploads/'
$pages = 'index.html', 'klinicki.html', 'zajednica.html', 'bold.html'
$dest  = Join-Path $root 'assets\img'
$utf8  = New-Object System.Text.UTF8Encoding $false
$rx    = '20\d{2}/\d{2}/[A-Za-z0-9._-]+\.(?:webp|jpe?g|png|gif|svg|avif)'

# Spisak slika se cita direktno iz HTML-a, pa skripta prati svaku izmenu stranica.
$paths = foreach ($f in $pages) {
  $html = [IO.File]::ReadAllText((Join-Path $root $f), $utf8)
  [regex]::Matches($html, $rx) | ForEach-Object { $_.Value }
}
$paths = @($paths | Sort-Object -Unique)

$fail = 0
foreach ($p in $paths) {
  $out = Join-Path $dest ($p -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
  try {
    Invoke-WebRequest -Uri ($base + $p) -OutFile $out -UseBasicParsing -UserAgent 'Mozilla/5.0' -Headers @{ Referer = 'https://www.menijepomoglo.rs/' }
    Write-Host "  OK      $p"
  } catch {
    $fail++
    Write-Host "  GRESKA  $p" -ForegroundColor Red
  }
}

if ($fail -gt 0) {
  Write-Host "Neuspesno: $fail od $($paths.Count) slika. HTML nije menjan - sajt i dalje koristi slike sa menijepomoglo.rs." -ForegroundColor Yellow
  exit 1
}

foreach ($f in $pages) {
  $file = Join-Path $root $f
  $html = [IO.File]::ReadAllText($file, $utf8)
  [IO.File]::WriteAllText($file, $html.Replace($base, 'assets/img/'), $utf8)
}
Write-Host "Gotovo: $($paths.Count) slika u assets\img\, HTML prebacen na lokalne putanje." -ForegroundColor Green

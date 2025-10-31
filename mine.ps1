# mine.ps1
# Miner Launcher Deluxe: retrowave barvy, cerne pozadi, gradient logo, vymazlene vystupy

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# -----------------------------
# Paleta barev
# -----------------------------
$ColorHeader      = "Magenta"     # titles
$ColorDivider     = "Cyan"        # separators
$ColorLogoDark    = "DarkBlue"
$ColorLogoMid1    = "Blue"
$ColorLogoMid2    = "Cyan"
$ColorItem        = "DarkMagenta" # unselected
$ColorSelectedBg  = "Magenta"     # selected background
$ColorSelectedFg  = "Black"
$ColorInfo        = "White"
$ColorWarn        = "Red"
$ColorStat        = "Cyan"
$ColorMuted       = "DarkGray"

# -----------------------------
# ASCII futuristicke logo
# -----------------------------
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$rocket = [string]::Join('', [char]0xD83D, [char]0xDE80)
$rocket = "🚀"
$rocket = ""
$logo = @"
  ____  _   _  ____  ____  __  __  ____  _   _
 / ___|| | | |/ ___||  _ \|  \/  |/ ___|| | | |
 \___ \| | | | |  _ | |_) | |\/| | |  _ | | | |
  ___) | |_| | |_| ||  __/| |  | | |_| || |_| |
 |____/ \___/ \____||_|   |_|  |_|\____| \___/
  ____  _   _  _____ _   _  __     __  ___
 |  _ \| | | |/ ____| \ | | \ \   / / |_ _|
 | |_) | |_| | (___ |  \| |  \ \ / /   | |
 |  _ <|  _  |\___ \| .   |   \ V /    | |
 | |_) | | | |____) | |\  |    | |    _| |_
 |____/|_| |_|_____/|_| \_|    |_|   |_____|
         M I N E R $rocket L A U N C H E R
"@

# -----------------------------
# Nastaveni konzole
# -----------------------------
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$raw = $Host.UI.RawUI
$size = $raw.WindowSize
if ($size.Width -lt 80) { $size.Width = 80 }
if ($size.Height -lt 25) { $size.Height = 25 }
$raw.WindowSize = $size

$size = New-Object System.Management.Automation.Host.Size(96,25)
$Host.UI.RawUI.WindowSize = $size

Clear-Host

# -----------------------------
# Prednastavene hodnoty
# -----------------------------
$wallet = "bc1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$worker = "desktop"

# -----------------------------
# Funkce: Logo s gradientem + glow
# -----------------------------
function Render-Logo-Gradient {
    param([string]$logoText)
    $lines  = $logoText -split "`n"
    $colors = @($ColorLogoDark,$ColorLogoMid1,$ColorLogoMid2,$ColorLogoMid1,$ColorLogoDark)
    foreach ($i in 0..($lines.Length-1)) {
        $c = $colors[$i % $colors.Length]
        # glow base
        Write-Host $lines[$i] -ForegroundColor $ColorLogoDark
        # bright line
        Write-Host $lines[$i] -ForegroundColor $c
    }
}

# -----------------------------
# Funkce: Menu
# -----------------------------
function Show-Menu-Neon {
    param (
        [string]$Title,
        [string[]]$Options
    )
    $selected = 0
    while ($true) {
        Clear-Host
        Render-Logo-Gradient -logoText $logo

        Write-Host ""
        Write-Host $Title -ForegroundColor $ColorHeader
        $lineWidth = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 4, 100)
        Write-Host ("=" * $lineWidth) -ForegroundColor $ColorDivider

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $item = $Options[$i]
            if ($i -eq $selected) {
                Write-Host ("  ► " + $item + "  ") -ForegroundColor $ColorSelectedFg -BackgroundColor $ColorSelectedBg
            } else {
                Write-Host ("    " + $item) -ForegroundColor $ColorItem
            }
        }

        Write-Host ""
        Write-Host "USE UP/DOWN and ENTER to select. PRESS R to reset, Q to quit." -ForegroundColor $ColorInfo

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { if ($selected -gt 0) { $selected-- } }
            40 { if ($selected -lt $Options.Length - 1) { $selected++ } }
            13 { return $Options[$selected] }
            81 { return "__QUIT__" }
            113 { return "__QUIT__" }
            82 { return "__RESET__" }
            114 { return "__RESET__" }
        }
    }
}

# -----------------------------
# Funkce: Spusteni mineru
# -----------------------------
function Run-Miner-With-Menu {
    Clear-Host
    Render-Logo-Gradient -logoText $logo

    $algos = @("kawpow","kawpow-amd", "firopow", "ghostrider", "verushash", "yespower", "randomx")
    $algo = Show-Menu-Neon -Title "SELECT ALGORITHM" -Options $algos
    if ($algo -eq "__QUIT__") { Write-Host "`nEXITING." -ForegroundColor $ColorDivider; return }
    if ($algo -eq "__RESET__") { & "$PSCommandPath" }

    switch ($algo) {
        "kawpow"     { $coins = @("AUTOMATIC", "RVN", "MEWC", "CLORE", "DYNAMIC (ZPOOL API)") }
        "firopow"    { $coins = @("AUTOMATIC") }
        "kawpow-amd" { $coins = @("AUTOMATIC") }
        "ghostrider" { $coins = @("AUTOMATIC", "RTM") }
        "verushash"  { $coins = @("AUTOMATIC", "VRSC") }
        "yespower"   { $coins = @("AUTOMATIC") }
    }
    $coinChoice = Show-Menu-Neon -Title ("SELECT COIN / MODE FOR " + $algo) -Options $coins
    if ($coinChoice -eq "__QUIT__") { Write-Host "`nEXITING." -ForegroundColor $ColorDivider; return }
    if ($coinChoice -eq "__RESET__") { & "$PSCommandPath" }

    if ($algo -eq "kawpow") {
        if ($coinChoice -eq "DYNAMIC (ZPOOL API)") {
            try {
                $response = Invoke-RestMethod "http://www.zpool.ca/api/status"
                $kawpowCoins = $response.pools | Where-Object { $_.algo -eq "kawpow" }
                $coin = ($kawpowCoins | Sort-Object estimate_current -Descending)[0].name
                Write-Host "`nBEST COIN FROM ZPOOL API: $coin" -ForegroundColor Green
		$zap = ",zap=$coin"
		$port = "1325"
		$miner = "t-rex"
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "`nERROR LOADING API. USING AUTO AS FALLBACK." -ForegroundColor $ColorWarn
                $zap = ""
		$port = "1325"
		$miner = "t-rex"
                Start-Sleep -Seconds 2
            }
        } else {
            $zap = ",zap=$coinChoice"
            $port = "1325"
            $miner = "t-rex"
        }
    } elseif ($algo -eq "firopow") {
            $zap = ",zap=$coinChoice"
            $port = "1326"
            $miner = "t-rex"
    } elseif ($algo -eq "ghostrider") {
            $zap = ",zap=$coinChoice"
            $port = "5354"
            $miner = "cpuminer-avx2-sha-vaes"
    } elseif ($algo -eq "verushash") {
            $zap = ",zap=$coinChoice"
            $port = "6143"
            $miner = "cpuminer-avx2-sha-vaes"
    } elseif ($algo -eq "yespower") {
            $zap = ",zap=$coinChoice"
            $port = "6234"
            $miner = "cpuminer-aes-sse42"
            $miner = "cpuminer-avx2-sha-vaes"
    } elseif ($algo -eq "kawpow-amd") {
            $algo = "kawpow"
            $zap = ",zap=$coinChoice"
            $port = "1325"
            $miner = "teamredminer"
            $extra = " -d 0 "
    } else {
            $zap = ""
            $port = "666"
            $miner = ""
    }

	if ($coinChoice -eq "AUTOMATIC") {
            $zap = ""
        }

    $server = "$algo.eu.mine.zpool.ca:$port"

    Clear-Host
    Render-Logo-Gradient -logoText $logo
    Write-Host "`nLAUNCHING: $coin ON $algo (EU SERVER)" -ForegroundColor Green
    $startTime = Get-Date

    try {
        Write-Host "`n.\$miner.exe -a $algo -o stratum+tcp://$server -u $wallet -p c=BTC$zap $extra" -ForegroundColor Magenta
        #& .\$miner.exe -a $algo -o stratum+tcp://$server -u $wallet -p c=BTC$zap $extra

Start-Process -FilePath ".\$miner.exe" `
    -ArgumentList "-a $algo -o stratum+tcp://$server -u $wallet -p c=BTC$zap $extra" `
    -Verb RunAs

    } catch {
        Write-Host "`nMINER INTERRUPTED OR ERROR: $($_.Exception.Message)" -ForegroundColor $ColorWarn
    } finally {
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host "`n----------------------------------------" -ForegroundColor $ColorMuted
        Write-Host "MINING STOPPED OR INTERRUPTED" -ForegroundColor $ColorMuted
        Write-Host "DURATION: $($duration.ToString("hh\:mm\:ss"))" -ForegroundColor $ColorStat
        Write-Host ("START : {0}" -f $startTime) -ForegroundColor $ColorInfo
        Write-Host ("END   : {0}" -f $endTime)   -ForegroundColor $ColorInfo
        Write-Host "----------------------------------------" -ForegroundColor $ColorMuted

        Write-Host "`nPRESS ENTER TO EXIT, OR TYPE R AND ENTER TO RESTART" -ForegroundColor Magenta
        $input = Read-Host "CHOICE (Enter / R)"

        if ($input -eq "R" -or $input -eq "r") {
            & "$PSCommandPath"
        } else {
            Write-Host "`nEXITING. KEEP YOUR HASHRATE HIGH." -ForegroundColor $ColorDivider
        }
    }
}

# -----------------------------
# Start
# -----------------------------
Run-Miner-With-Menu

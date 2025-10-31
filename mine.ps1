# mine.ps1
# Miner Launcher Deluxe: retrowave barvy, cerne pozadi, gradient logo, vymazlene vystupy

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# -----------------------------
# Paleta barev
# -----------------------------
$ColorHeader      = "Magenta"
$ColorDivider     = "Cyan"
$ColorLogoDark    = "DarkBlue"
$ColorLogoMid1    = "Blue"
$ColorLogoMid2    = "Cyan"
$ColorItem        = "DarkMagenta"
$ColorSelectedBg  = "Magenta"
$ColorSelectedFg  = "Black"
$ColorInfo        = "White"
$ColorWarn        = "Red"
$ColorStat        = "Cyan"
$ColorMuted       = "DarkGray"

# -----------------------------
# ASCII futuristicke logo
# -----------------------------
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
$size = New-Object System.Management.Automation.Host.Size(96,36)
$Host.UI.RawUI.WindowSize = $size
Clear-Host

# -----------------------------
# Nacteni konfigurace
# -----------------------------
$config = Get-Content ".\config.json" | ConvertFrom-Json

# -----------------------------
# Funkce: Logo s gradientem
# -----------------------------
function Render-Logo-Gradient {
    param([string]$logoText)
    $lines  = $logoText -split "`n"
    $colors = @($ColorLogoDark,$ColorLogoMid1,$ColorLogoMid2,$ColorLogoMid1,$ColorLogoDark)
    foreach ($i in 0..($lines.Length-1)) {
        $c = $colors[$i % $colors.Length]
        Write-Host $lines[$i] -ForegroundColor $ColorLogoDark
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

    $algos = $config.miners.algo | Sort-Object -Unique
    $algo = Show-Menu-Neon -Title "SELECT ALGORITHM" -Options $algos
    if ($algo -eq "__QUIT__") { Write-Host "`nEXITING." -ForegroundColor $ColorDivider; return }
    if ($algo -eq "__RESET__") { & "$PSCommandPath" }

    $minerConfig = $config.miners | Where-Object { $_.algo -eq $algo }

    if (-not $minerConfig) {
        Write-Host "`nERROR: No config found for $algo" -ForegroundColor $ColorWarn
        return
    }

    $miner  = $minerConfig.miner
    $port   = $minerConfig.port
    $wallet = $minerConfig.wallet
    $extra  = $minerConfig.extra

    if ($minerConfig.server) {
        $server = $minerConfig.server
    } else {
        $server = "stratum+tcp://$algo.eu.mine.zpool.ca:$port"
    }

    Clear-Host
    Render-Logo-Gradient -logoText $logo
    Write-Host "`nLAUNCHING: $algo miner on EU server" -ForegroundColor Green
    $startTime = Get-Date

    try {
        
        $arguments = "-a $algo -o stratum+tcp://$server -u $wallet -p c=BTC $extra"

        Write-Host "`n.\$miner.exe $arguments" -ForegroundColor Magenta

        if ($minerConfig.elevated -eq $true) {
            Start-Process -FilePath ".\$miner.exe" -ArgumentList $arguments -Verb RunAs
        } else {
            & ".\$miner.exe" $arguments
        }


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
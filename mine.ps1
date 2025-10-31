# mine.ps1
# Futuristic console menu pro T-Rex (EU server)
# Retrowave barvy, cerne pozadi, tucne menu, gradient logo

$logo = @"
  ____  _   _  ____  ____  __  __  ____  _   _
 / ___|| | | |/ ___||  _ \|  \/  |/ ___|| | | |
 \___ \| | | | |  _ | |_) | |\/| | |  _ | | | |
  ___) | |_| | |_| ||  __/| |  | | |_| || |_| |
 |____/ \___/ \____||_|   |_|  |_|\____| \___/
  ____  _   _  _____ _   _  __     __  ___
 |  _ \| | | |/ ____| \ | | \ \   / / |_ _|
 | |_) | |_| | (___ |  \| |  \ \ / /   | |
 |  _ <|  _  |\___ \| . ` |   \ V /    | |
 | |_) | | | |____) | |\  |    | |    _| |_
 |____/|_| |_|_____/|_| \_|    |_|   |_____|
"@

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

$wallet = "bc1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$worker = "worker1"

function Render-Logo-Gradient {
    param([string]$logoText)
    $lines = $logoText -split "`n"
    $colors = @("DarkBlue","Blue","Cyan","Blue","DarkBlue")
    for ($i=0; $i -lt $lines.Length; $i++) {
        $color = $colors[$i % $colors.Length]
        Write-Host $lines[$i] -ForegroundColor $color
    }
}

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
        Write-Host $Title -ForegroundColor Magenta
        Write-Host ("=" * ([Math]::Min(70, ($Title.Length + 10)))) -ForegroundColor Cyan

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $item = $Options[$i]
            if ($i -eq $selected) {
                Write-Host ("  ► " + $item + "  ") -ForegroundColor Black -BackgroundColor Magenta
            } else {
                Write-Host ("    " + $item) -ForegroundColor DarkMagenta
            }
        }

        Write-Host ""
        Write-Host "USE UP/DOWN and ENTER to select. PRESS Q to quit." -ForegroundColor White

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { if ($selected -gt 0) { $selected-- } }
            40 { if ($selected -lt $Options.Length - 1) { $selected++ } }
            13 { return $Options[$selected] }
            81 { return "__QUIT__" }
            113 { return "__QUIT__" }
        }
    }
}

function Run-Miner-With-Menu {
    Clear-Host
    Render-Logo-Gradient -logoText $logo

    $algos = @("KawPoW", "Ethash", "Equihash")
    $algo = Show-Menu-Neon -Title "SELECT ALGORITHM" -Options $algos
    if ($algo -eq "__QUIT__") { Write-Host "`nEXITING." -ForegroundColor Cyan; return }

    switch ($algo) {
        "KawPoW"   { $coins = @("RVN", "MEWC", "CLORE", "AUTO (ZPOOL auto)", "DYNAMIC (ZPOOL API)") }
        "Ethash"   { $coins = @("ETC", "EXP") }
        "Equihash" { $coins = @("ZEC", "KMD") }
    }
    $coinChoice = Show-Menu-Neon -Title ("SELECT COIN / MODE FOR " + $algo) -Options $coins
    if ($coinChoice -eq "__QUIT__") { Write-Host "`nEXITING." -ForegroundColor Cyan; return }

    if ($algo -eq "KawPoW") {
        if ($coinChoice -eq "AUTO (ZPOOL auto)") {
            $coin = "auto"
        } elseif ($coinChoice -eq "DYNAMIC (ZPOOL API)") {
            try {
                $response = Invoke-RestMethod "http://www.zpool.ca/api/status"
                $kawpowCoins = $response.pools | Where-Object { $_.algo -eq "kawpow" }
                $coin = ($kawpowCoins | Sort-Object estimate_current -Descending)[0].name
                Write-Host "`nBEST COIN FROM ZPOOL API: $coin" -ForegroundColor Green
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "`nERROR LOADING API. USING RVN AS FALLBACK." -ForegroundColor Red
                $coin = "RVN"
                Start-Sleep -Seconds 2
            }
        } else {
            $coin = $coinChoice
        }
    } else {
        $coin = $coinChoice
    }

    $server = "$algo.eu.mine.zpool.ca:1325"

    Clear-Host
    Render-Logo-Gradient -logoText $logo
    Write-Host "`nLAUNCHING: $coin ON $algo (EU SERVER)" -ForegroundColor Green
    $startTime = Get-Date

    try {
        & .\t-rex.exe -a $algo -o stratum+tcp://$server -u $wallet -p c=BTC,mc=$coin -w $worker
    } catch {
        Write-Host "`nMINER INTERRUPTED OR ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host | Out-Null
    } finally {
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
        Write-Host "MINING STOPPED OR INTERRUPTED" -ForegroundColor DarkGray
        Write-Host "DURATION: $($duration.ToString("hh\:mm\:ss"))" -ForegroundColor Cyan
        Write-Host ("START : {0}" -f $startTime) -ForegroundColor Gray
        Write-Host ("END   : {0}" -f $endTime) -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host "`nPRESS ENTER TO EXIT, OR TYPE R AND ENTER TO RESTART" -ForegroundColor Cyan

        $input = Read-Host "CHOICE (Enter / R)"

        if ($input -eq "R" -or $input -eq "r") {
            & "$PSCommandPath"
        } else {
            Write-Host "`nEXITING. KEEP YOUR HASHRATE HIGH." -ForegroundColor Cyan
        }
    }
}

# Start
Run-Miner-With-Menu

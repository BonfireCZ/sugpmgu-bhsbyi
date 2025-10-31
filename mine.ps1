# mine.ps1
# Futuristic console menu pro T-Rex (EU server)
# Bez diakritiky, cerne pozadi, miner bezi ve stejnem okne.
# Po ukonceni (vcetne Ctrl+C) zobrazi info o dobe tezby a nabidne restart.

# ASCII futuristicke logo
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

# Nastaveni konzole
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Gray"
Clear-Host
Write-Host $logo -ForegroundColor Cyan

# Prednastavena BTC adresa a worker
$wallet = "bc1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$worker = "worker1"

function Show-Menu {
    param (
        [string]$Title,
        [string[]]$Options
    )
    $selected = 0
    while ($true) {
        Clear-Host
        Write-Host $logo -ForegroundColor Cyan
        Write-Host "`n$Title`n" -ForegroundColor Cyan
        for ($i = 0; $i -lt $Options.Length; $i++) {
            if ($i -eq $selected) {
                Write-Host (" > {0}" -f $Options[$i]) -ForegroundColor Yellow
            } else {
                Write-Host ("   {0}" -f $Options[$i])
            }
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { if ($selected -gt 0) { $selected-- } }    # Up
            40 { if ($selected -lt $Options.Length - 1) { $selected++ } } # Down
            13 { return $Options[$selected] }               # Enter
        }
    }
}

function Run-Miner-With-Menu {
    Clear-Host
    Write-Host $logo -ForegroundColor Cyan

    # Vyber algoritmu
    $algos = @("KawPoW", "Ethash", "Equihash")
    $algo = Show-Menu -Title "SELECT ALGORITHM" -Options $algos

    # Vyber coinu podle algoritmu
    switch ($algo) {
        "KawPoW"   { $coins = @("RVN", "MEWC", "CLORE", "AUTO (ZPOOL auto)", "DYNAMIC (ZPOOL API)") }
        "Ethash"   { $coins = @("ETC", "EXP") }
        "Equihash" { $coins = @("ZEC", "KMD") }
    }
    $coinChoice = Show-Menu -Title ("SELECT COIN / MODE FOR " + $algo) -Options $coins

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

    # EU server pevne nastavene
    $server = "$algo.eu.mine.zpool.ca:3633"

    Clear-Host
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "`nLAUNCHING: $coin ON $algo (EU SERVER)" -ForegroundColor Green
    $startTime = Get-Date

    try {
        & .\t-rex.exe -a $algo -o stratum+tcp://$server -u $wallet -p c=BTC,mc=$coin -w $worker
    } catch {
        Write-Host "`nMINER INTERRUPTED OR ERROR: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
        Write-Host "MINING STOPPED OR INTERRUPTED" -ForegroundColor DarkGray
        Write-Host ("DURATION: {0:hh\\:mm\\:ss}" -f $duration) -ForegroundColor Cyan
        Write-Host ("START : {0}" -f $startTime) -ForegroundColor Gray
        Write-Host ("END   : {0}" -f $endTime) -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor DarkGray

        Write-Host "`nPRESS ENTER TO EXIT, OR TYPE R AND ENTER TO RESTART" -ForegroundColor Gray
        $input = Read-Host "CHOICE (Enter / R)"

        if ($input -eq "R" -or $input -eq "r") {
            # restart current script
            & "$PSCommandPath"
        } else {
            Write-Host "`nEXITING. KEEP YOUR HASHRATE HIGH." -ForegroundColor Cyan
        }
    }
}

# Start
Run-Miner-With-Menu

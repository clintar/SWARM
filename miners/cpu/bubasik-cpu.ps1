$CPUTypes | ForEach-Object {
    
    $ConfigType = $_;

    ##Miner Path Information
    if ($cpu.bubasik.$ConfigType) { $Path = "$($cpu.bubasik.$ConfigType)" }
    else { $Path = "None" }
    if ($cpu.bubasik.uri) { $Uri = "$($cpu.bubasik.uri)" }
    else { $Uri = "None" }
    if ($cpu.bubasik.minername) { $MinerName = "$($cpu.bubasik.minername)" }
    else { $MinerName = "None" }

    $Name = "bubasik";

    ##Log Directory
    $Log = Join-Path $($global:Dir) "logs\$ConfigType.log"

    ##Parse -CPUThreads
    if ($global:Config.Params.CPUThreads -ne '') { $Devices = $global:Config.Params.CPUThreads }

    ##Get Configuration File
    $GetConfig = "$($global:Dir)\config\miners\bubasik.json"
    try { $MinerConfig = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Log "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($global:Dir) "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl.so.4.5.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Exclusions.$MinerAlgo.exclusions -and $ConfigType -notin $global:Exclusions.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
        if ($Check.RAW -ne "Bad") {
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Coins
                        Delay      = $MinerConfig.$ConfigType.delay
                        Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($_.Symbol)"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        Devices    = $Devices
                        DeviceCall = "cpuminer-opt"
                        Arguments  = "-a $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:10001 -u $($_.User1) -p $($_.Pass1)$($Diff) $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        Port       = 10001
                        API        = "cpuminer"
                        Wallet     = "$($_.User1)"
                        URI        = $Uri
                        Server     = "localhost"
                        Algo       = "$($_.Algorithm)"
                        Log        = $Log 
                    }            
                }
            }     
        }
    }
}
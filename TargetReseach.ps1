function Test-Port {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, HelpMessage = 'Could be suffixed by :Port')]
        [String[]]$ComputerName,

        [Parameter(HelpMessage = 'Will be ignored if the port is given in the param ComputerName')]
        [Int]$Port = 5985,

        [Parameter(HelpMessage = 'Timeout in millisecond. Increase the value if you want to test Internet resources.')]
        [Int]$Timeout = 1000
    )

    begin {
        $result = [System.Collections.ArrayList]::new()
    }

    process {
        foreach ($originalComputerName in $ComputerName) {
            $remoteInfo = $originalComputerName.Split(":")
            if ($remoteInfo.count -eq 1) {
                # In case $ComputerName in the form of 'host'
                $remoteHostname = $originalComputerName
                $remotePort = $Port
            } elseif ($remoteInfo.count -eq 2) {
                # In case $ComputerName in the form of 'host:port',
                # we often get host and port to check in this form.
                $remoteHostname = $remoteInfo[0]
                $remotePort = $remoteInfo[1]
            } else {
                $msg = "Got unknown format for the parameter ComputerName: " `
                    + "[$originalComputerName]. " `
                    + "The allowed formats is [hostname] or [hostname:port]."
                Write-Error $msg
                return
            }

            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $portOpened = $tcpClient.ConnectAsync($remoteHostname, $remotePort).Wait($Timeout)

            $null = $result.Add([PSCustomObject]@{
                RemoteHostname       = $remoteHostname
                RemotePort           = $remotePort
                PortOpened           = $portOpened
                TimeoutInMillisecond = $Timeout
                SourceHostname       = $env:COMPUTERNAME
                OriginalComputerName = $originalComputerName
                })
        }
    }

    end {
        return $result
    }
}

$targets = Import-Csv c:\temp\reports\targets.csv

#Change the path of log file to a desired location below
$recordPath = "C:\temp\reports\"

#Build the log file name.  Do not update this variable
$recordFile = $recordPath + "targetinfo" + ".csv"

Echo "target,rootdomain,domain,pip,isp,org,443opened" | Out-File $recordFile

foreach ($target in $targets){

    $targetname = $target.targetName
    $rootdomain = $target.domain

    $hturl = "https://api.hackertarget.com/hostsearch/?q=" + $target.domain

    $result = Invoke-WebRequest -Uri $hturl

    $results = $result.Content
    $listarray = $results.split("`r?`n")

    $formula = $listarray.count / 44
    $formula2 = $Formula * 65
    $Formula3 = $Formula2 / 60

    Write-Host -ForegroundColor Yellow "Due to API rate limits we back off - Estimated Time:" $Formula3 "minutes"

    $counter = 0
    Foreach ($result in $listarray) {

        $counter++

        Write-host $counter
        if ($counter -le 43) {
    
            $domain = $result.Split(',')[0]
            $pip = $result.Split(',')[1]
            $lookuppip = Invoke-WebRequest http://ip-api.com/json/$pip
            $isp = ($lookuppip.Content | ConvertFrom-Json).isp
            $org = ($lookuppip.Content | ConvertFrom-Json).org

            $check443open = Test-Port -ComputerName $pip -Port 443

            #Write-Host $domain "," $pip "," $isp "," $org
            $stringinsert = $targetname + "," + $rootdomain + "," + $domain + "," + $pip + "," + $isp + "," + $org + "," + $check443open.PortOpened
            Echo $stringinsert | Out-File $recordFile -Append

        }
        else {
    
            Start-Sleep -Seconds 65
            $counter = 0
    
        }

    }
    Start-Sleep -Seconds 65
}
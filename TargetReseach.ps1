$targets = Import-Csv c:\temp\reports\targets.csv

#Change the path of log file to a desired location below
$recordPath = "C:\temp\reports\"

#Build the log file name.  Do not update this variable
$recordFile = $recordPath + "targetinfo" + ".csv"

Echo "target,rootdomain,domain,pip,isp,org" | Out-File $recordFile

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

            #Write-Host $domain "," $pip "," $isp "," $org
            $stringinsert = $targetname + "," + $rootdomain + "," + $domain + "," + $pip + "," + $isp + "," + $org
            Echo $stringinsert | Out-File $recordFile -Append

        }
        else {
    
            Start-Sleep -Seconds 65
            $counter = 0
    
        }

    }
    Start-Sleep -Seconds 65
}
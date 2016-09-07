function writeToJSON {
param
    ($Map) 
    $list = @()

    $Map.GetEnumerator() | % {
        $list += $_.Value
    }
    ConvertTo-Json $list | Out-File -FilePath "info.json" -Force
}

$Hostnames = Get-Content "hostnames.txt"

$hosts = @{}

$Hostnames | foreach {
    Write-Host("$_")
    $cred = Get-Credential -Message "Getting credentials for $_" -UserName "$_\"
    $hosts.add($_, $cred)
} 

  
  $codeBlock = {
    param($creds, $hostname)
    Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock {
        $a = Get-Counter
        $value = New-Object System.Object
        $value | Add-Member -type NoteProperty -Name Name -Value $(hostname)
        $netValue = 0;
        $a.CounterSamples | foreach {
           if ($_.Path.Contains("network")) {
            $netValue += $_.CookedValue
           }
           elseif ($_.Path.Contains("processor")) {
            $value | Add-Member -type NoteProperty -Name CPU -Value $([math]::Round($_.CookedValue,2))    
           } 
           elseif ($_.Path.Contains("memory\%")) {
            $value | Add-Member -type NoteProperty -Name Memory -Value $([math]::Round($_.CookedValue,2))         
           }
           elseif ($_.Path.Contains("disk time")) {
            $value | Add-Member -type NoteProperty -Name Disk -Value $([math]::Round($_.CookedValue,2))         
           }
        }

        $value | Add-Member -type NoteProperty -Name Timestamp -Value $a.Timestamp.DateTime
        $value | Add-Member -type NoteProperty -Name Network -Value $([math]::Round($netValue,2))    
        $value
    }
}

$jobs = @{}

$hosts.GetEnumerator() | % {
    $job = Start-Job $codeBlock -ArgumentList $_.Value, $_.Key
    $jobs.add( $_.Key, $job.Id)
}

#$job = Start-Job $codeBlock -ArgumentList $creds, "Tec-7040-itb-01"
#$job = Start-Job $codeBlock -ArgumentList $creds, ""



$values = @{}

#Job deletion get's weird if we don't let it get it's bearings. 
Start-Sleep -Milliseconds 5000

#run until we tell it to stop
while($true) {
    $q = Get-Job -State Completed 
    $c = $q | Receive-Job
    if ($c) {

        $c | foreach {
            if ($values.ContainsKey($_.Name)) {
                $values[$_.Name] = $_
            } else {
                $values.Add($_.Name, $_)
            }
            writeToJSON -Map $values
            Remove-Job -Id $jobs[$_.Name]

            Write-Host("Running")
            $job = Start-Job $codeBlock -ArgumentList $hosts[$_.Name], $_.Name
            $jobs[$_.Name] = $job.Id
        }
    }
    Start-Sleep -Milliseconds 500
}
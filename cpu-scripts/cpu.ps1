# List of process name patterns to monitor (partial matches)
$processNames = @("quicknano", "QtWeb")

# Maximum number of processes to monitor per pattern
$maxProcessesPerPattern = 8
# Output CSV file
$outputFile = "$PSScriptRoot\cpu_usage.csv"

# Build header dynamically
$header = "Timestamp"
foreach ($pname in $processNames) {
    for ($i = 1; $i -le $maxProcessesPerPattern; $i++) {
        $header += ",${pname}_Process_Name_$i,${pname}_ProcessId_$i,${pname}_CPU_Usage_$i"
    }
}
$header | Out-File -FilePath $outputFile -Encoding utf8

# Number of logical processors (used in CPU usage calculation)
$logicalProcessors = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors

# Sampling interval in milliseconds
$intervalMilliseconds = 500

# Infinite loop to monitor processes every second
while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp"
    $processData = @{}

    # Collect initial CPU times for all processes
    foreach ($pname in $processNames) {
        # Get processes whose names contain the pattern (partial match)
        $processes = Get-Process | Where-Object { $_.ProcessName -like "*$pname*" }
        $processes = $processes | Select-Object -First $maxProcessesPerPattern

        # Store initial CPU times
        foreach ($proc in $processes) {
            $key = "$($pname)_$($proc.Id)"
            if (-not $processData.ContainsKey($key)) {
                $processData[$key] = @{
                    'ProcessName' = $proc.ProcessName
                    'ProcessId' = $proc.Id
                    'CPU1' = $proc.CPU
                }
            }
        }
    }

    # Wait for the interval
    Start-Sleep -Milliseconds $intervalMilliseconds

    # Collect final CPU times for all processes
    foreach ($key in $processData.Keys) {
        $processId = $processData[$key]['ProcessId']
        $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($proc -ne $null) {
            $processData[$key]['CPU2'] = $proc.CPU
        } else {
            # Process may have exited; mark CPU2 as null
            $processData[$key]['CPU2'] = $null
        }
    }

    # Build the line with process data
    foreach ($pname in $processNames) {
        $count = 0
        foreach ($key in $processData.Keys) {
            if ($key -like "$pname*") {
                $count++
                $procInfo = $processData[$key]
                $procName = $procInfo['ProcessName'] -replace ',', ''
                $processId = $procInfo['ProcessId']
                $cpu1 = $procInfo['CPU1']
                $cpu2 = $procInfo['CPU2']

                if ($cpu2 -ne $null -and $cpu2 -ge $cpu1) {
                    $cpuDelta = $cpu2 - $cpu1
                    if ($cpuDelta -lt 0) {
                        $cpuDelta = 0
                    }
                    $cpuUsage = ($cpuDelta / ($intervalMilliseconds / 1000)) * 100 / $logicalProcessors
                    $cpuUsage = [math]::Round($cpuUsage, 2)
                } else {
                    $cpuUsage = 0
                }

                # Add to line
                $line += ",`"$procName`",$processId,$cpuUsage"

                if ($count -ge $maxProcessesPerPattern) {
                    break
                }
            }
        }
        # If fewer processes than maximum, add empty fields
        for ($i = $count + 1; $i -le $maxProcessesPerPattern; $i++) {
            $line += ",,,"
        }
    }

    # Write data to CSV file
    $line | Out-File -FilePath $outputFile -Append -Encoding utf8
    # Also output to screen
    Write-Host $line

    # Wait for the next cycle
    Start-Sleep -Milliseconds 500
}
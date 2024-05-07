# Input bindings are passed in via param block.
param([byte[]] $InputBlob, $TriggerMetadata)

Import-Module Az.Storage -RequiredVersion '2.2.0'

function Get-DistanceInKilometers {
    param(
        [double]$lat1,
        [double]$lon1,
        [double]$lat2,
        [double]$lon2
    )

    $R = 6371  # Earth's radius in kilometers

    $dLat = ($lat2 - $lat1) * [math]::PI / 180
    $dLon = ($lon2 - $lon1) * [math]::PI / 180

    $a = [math]::Sin($dLat / 2) * [math]::Sin($dLat / 2) + [math]::Cos($lat1 * [math]::PI / 180) * [math]::Cos($lat2 * [math]::PI / 180) * [math]::Sin($dLon / 2) * [math]::Sin($dLon / 2)
    $c = 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))

    $distance = $R * $c
    return $distance
}

# Starting Logging Procedure
Start-Transcript -Path "$env:TEMP\TaxiStatsLog.log" -IncludeInvocationHeader

$date = Get-Date

# Converting Input To CSV
Write-Host "$(Get-Date): Reading Files Contents"
[string]$blobContent = [System.Text.Encoding]::UTF8.GetString($InputBlob)
$allRides = $blobContent |  ConvertFrom-Csv

# Creating Tables
Write-Host "$(Get-Date): Creating Required Tables"
$tableq1 = New-Object System.Data.DataTable
$tableq2 = New-Object System.Data.DataTable
$tableq3 = New-Object System.Data.DataTable
$tableq5 = New-Object System.Data.DataTable
$tableAllDataset = New-Object System.Data.DataTable

$tableq1.Columns.Add("q1")
$tableq1.Columns.Add("q2")
$tableq1.Columns.Add("q3")
$tableq1.Columns.Add("q4")

$tableq2.Columns.Add("key") | out-null
$tableq2.Columns.Add("fare_amount") | out-null
$tableq2.Columns.Add("pickup_datetime") | out-null
$tableq2.Columns.Add("pickup_longitude") | out-null
$tableq2.Columns.Add("pickup_latitude") | out-null
$tableq2.Columns.Add("dropoff_longitude") | out-null
$tableq2.Columns.Add("dropoff_latitude") | out-null
$tableq2.Columns.Add("passenger_count") | out-null
$tableq2.Columns.Add("distance") | out-null
$tableq2.Columns.Add("quarter") | out-null

$tableq3.Columns.Add("time")

$tableq5.Columns.Add("time")
$tableq5.Columns.Add("distance")

$tableAllDataset.Columns.Add("key") | out-null
$tableAllDataset.Columns.Add("fare_amount") | out-null
$tableAllDataset.Columns.Add("pickup_datetime") | out-null
$tableAllDataset.Columns.Add("pickup_longitude") | out-null
$tableAllDataset.Columns.Add("pickup_latitude") | out-null
$tableAllDataset.Columns.Add("dropoff_longitude") | out-null
$tableAllDataset.Columns.Add("dropoff_latitude") | out-null
$tableAllDataset.Columns.Add("passenger_count") | out-null
$tableAllDataset.Columns.Add("distance") | out-null
$tableAllDataset.Columns.Add("quarter") | out-null

# Initializing Quarter Counters
Write-Host "$(Get-Date): Initializing Values"
$FromQ1 = 0
$FromQ2 = 0
$FromQ3 = 0
$FromQ4 = 0

# Other Initializations
[double]$centralLatitude = 40.735923
[double]$centralLongitude = -73.990294
$dateFormat = "yyyy-MM-dd HH:mm:ss UTC"
$count = 0

Write-Host "$(Get-Date): Starting Main Loop"
# Foreach Ride, Do Appropriate Calculations
foreach($ride in $allRides)
{
    $dateTime = [datetime]::ParseExact($ride.pickup_datetime, $dateFormat, [System.Globalization.CultureInfo]::InvariantCulture)
    
    $q2satisfied = $false
    # Calculating Distance
    $distance = 0
    $distance = Get-DistanceInKilometers -lat1 $ride.pickup_latitude -lon1 $ride.pickup_longitude -lat2 $ride.dropoff_latitude -lon2 $ride.dropoff_longitude
    if(($distance -gt 1) -and ($($ride.passenger_count) -gt 2) -and ([double]$($ride.fare_amount) -gt 10))
    {
        $count +=1
        $tableq3.Rows.Add($dateTime.Hour) | out-null
        $q2satisfied = $true
    }

    # Checking in Which Quarter Each Ride Belongs
    if ([double]($ride.pickup_latitude) -gt $centralLatitude) 
    {
        if ([double]($ride.pickup_longitude) -gt $centralLongitude) 
        {
            $FromQ1++
            $tableAllDataset.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q1") | out-null
            if($q2satisfied)
            {
                $tableq2.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q1") | out-null
            }
        } 
        else 
        {
            $FromQ2++
            $tableAllDataset.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q2") | out-null
            if($q2satisfied)
            {
                $tableq2.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q2") | out-null
            }
        }
    } 
    else 
    {
        if ([double]($ride.pickup_longitude) -gt $centralLongitude) 
        {
            $FromQ3++
            $tableAllDataset.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q3") | out-null
            if($q2satisfied)
            {
                $tableq2.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q3") | out-null
            }
        } else 
        {
            $FromQ4++
            $tableAllDataset.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q4") | out-null
            if($q2satisfied)
            {
                $tableq2.Rows.Add($ride.key, $ride.fare_amount, $ride.pickup_datetime, $ride.pickup_longitude, $ride.pickup_latitude, $ride.dropoff_longitude, $ride.dropoff_latitude, $ride.passenger_count, $distance, "Q4") | out-null
            }
        }
    }

    $distanceQuery5 = 0
    $distanceQuery5 = Get-DistanceInKilometers -lat1 $centralLatitude -lon1 $centralLongitude -lat2 $ride.pickup_latitude -lon2 $ride.pickup_longitude

    if (($distanceQuery5 -le 5) -and ([double]$($ride.fare_amount) -gt 10))
    {
        if($dateTime.Hour -gt 11)
        {
            $tableq5.Rows.Add("$($dateTime.Hour)pm", $distanceQuery5)
        }
        else 
        {
            $tableq5.Rows.Add("$($dateTime.Hour)am", $distanceQuery5)
        }
    }
}
Write-Host "$(Get-Date): Exited Main Loop"
# General Stats
Write-Host "$(Get-Date): Total Number of Rides: $($allRides.Count)"
Write-Host "$(Get-Date): Q1 Rides Per Quarter. Q1: $FromQ1, Q2: $FromQ2, Q3:$FromQ3, Q4: $FromQ4"
Write-Host "$(Get-Date): Q2 Number of Records: $count"

#Adding Quarter Counters To Table for Query 1 
$tableq1.Rows.Add($FromQ1, $FromQ2, $FromQ3, $FromQ4)

# Results For Query3
$q3TimeResults = $tableq3 | Group-Object -Property time | Sort-Object -Property Count -Descending | Select-Object @{Name='Time'; Expression={$_.Name}}, Count -First 5 
$q3QuarterResults = $tableq2 | Group-Object -Property quarter | Sort-Object -Property Count -Descending | Select-Object @{Name='Quarter'; Expression={$_.Name}}, Count 

# Results For Query 5
$q5Results = $tableq5 | Group-Object -Property time | Sort-Object -Property Count -Descending | Select-Object @{Name='Time'; Expression={$_.Name}}, Count 

# Specify the container name and file name
$containerName = "newyorktaxicontainer"

# Storage Account Connection String 
$storageConnectionString = "Add Connection String Here"

# Create a storage context using the connection string
$storageContext = New-AzStorageContext -ConnectionString $storageConnectionString

# Convert tables to CSVs
Write-Host "$(Get-Date): Exporting To CSVs"
try
{
    $tableq1 | Export-Csv -NoTypeInformation -Path "$env:TEMP\Query1Results.csv" -Encoding UTF8 -ErrorAction Stop
    $tableq2 | Export-Csv -NoTypeInformation -Path "$env:TEMP\Query2Results.csv" -Encoding UTF8 -ErrorAction Stop
    $q3TimeResults | Export-Csv -NoTypeInformation -Path "$env:TEMP\Query3TimeResults.csv" -Encoding UTF8 -ErrorAction Stop
    $tableAllDataset | Export-Csv -NoTypeInformation -Path "$env:TEMP\CompleteDatasetMoreInfo.csv" -Encoding UTF8 -ErrorAction Stop
    $q3QuarterResults | Export-Csv -NoTypeInformation -Path "$env:TEMP\Query3QuarterResults.csv" -Encoding UTF8 -ErrorAction Stop
    $q5Results | Export-Csv -NoTypeInformation -Path "$env:TEMP\Query5Results.csv" -Encoding UTF8 -ErrorAction Stop
}
catch
{
    Write-Host "$(Get-Date): Error Exporting To CSVs"

    # Calculating Execution Time
    $endtime = Get-Date
    $executionTime = ($endTime - $date).TotalSeconds
    Write-Host "$(Get-Date): Total Execution Time: $executionTime seconds"
    Write-Host "$(Get-Date): Exiting"

    Stop-Transcript

    # Log File To Storage Account
    Set-AzStorageBlobContent `
        -File "$env:TEMP\TaxiStatsLog.log" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop
    EXIT 
}
Write-Host "$(Get-Date): Successfully Exported Results To CSVs"

# Upload CSVs to Azure Storage
try
{
    Write-Host "$(Get-Date): Saving CSVs To Storage Account"
    Set-AzStorageBlobContent `
        -File "$env:TEMP\Query1Results.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop

    Set-AzStorageBlobContent `
        -File "$env:TEMP\Query2Results.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop

    Set-AzStorageBlobContent `
        -File "$env:TEMP\Query3TimeResults.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop

    Set-AzStorageBlobContent `
        -File "$env:TEMP\Query3QuarterResults.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop

    Set-AzStorageBlobContent `
        -File "$env:TEMP\CompleteDatasetMoreInfo.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop

    Set-AzStorageBlobContent `
        -File "$env:TEMP\Query5Results.csv" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop
}
catch
{
    Write-Host "$(Get-Date): Error Saving CSVs To Storage"

    # Calculating Execution Time
    $endtime = Get-Date
    $executionTime = ($endTime - $date).TotalSeconds
    Write-Host "$(Get-Date): Total Execution Time: $executionTime seconds"
    Write-Host "$(Get-Date): Exiting"

    Stop-Transcript

    # Log File To Storage Account
    Set-AzStorageBlobContent `
        -File "$env:TEMP\TaxiStatsLog.log" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop
    EXIT
}
Write-Host "$(Get-Date): Successfully Saved CSVs To Storage Account"

# Remove Files From Temp Folder
Write-Host "$(Get-Date): Removing CSVs From Temp Folder"
try{
    Remove-Item -Path "$env:TEMP\Query1Results.csv" -ErrorAction Stop
    Remove-Item -Path "$env:TEMP\Query2Results.csv" -ErrorAction Stop
    Remove-Item -Path "$env:TEMP\Query3TimeResults.csv" -ErrorAction Stop
    Remove-Item -Path "$env:TEMP\CompleteDatasetMoreInfo.csv" -ErrorAction Stop
    Remove-Item -Path "$env:TEMP\Query3QuarterResults.csv" -ErrorAction Stop
    Remove-Item -Path "$env:TEMP\Query5Results.csv" -ErrorAction Stop
}
catch
{
    Write-Host "$(Get-Date): Error Removing CSVs From Temp Folder"

    # Calculating Execution Time
    $endtime = Get-Date
    $executionTime = ($endTime - $date).TotalSeconds
    Write-Host "$(Get-Date): Total Execution Time: $executionTime seconds"
    Write-Host "$(Get-Date): Exiting"

    Stop-Transcript

    # Log File To Storage Account
    Set-AzStorageBlobContent `
        -File "$env:TEMP\TaxiStatsLog.log" `
        -Container $containerName `
        -Context $storageContext `
        -Force `
        -ErrorAction Stop
    
}

Write-Host "$(Get-Date): Successfully Removed CSVs From Temp Folder"

# Calculating Execution Time
$endtime = Get-Date
$executionTime = ($endTime - $date).TotalSeconds
Write-Host "$(Get-Date): Total Execution Time: $executionTime seconds"
Write-Host "$(Get-Date): Exiting"

Stop-Transcript

# Log File To Storage Account
Set-AzStorageBlobContent `
    -File "$env:TEMP\TaxiStatsLog.log" `
    -Container $containerName `
    -Context $storageContext `
    -Force `
    -ErrorAction Stop


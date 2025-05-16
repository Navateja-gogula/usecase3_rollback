param(
    [string]$LocalServer,
    [string]$RemoteServer,
    [string]$LocalDB,
    [string]$RemoteDB,
    [string]$LocalTable,
    [string]$RemoteTable,
    [string]$User,
    [string]$LocalPassword,
    [string]$RemotePassword
)

function Execute-Query($connectionString, $query) {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    $reader = $cmd.ExecuteReader()
    $table = New-Object System.Data.DataTable
    $table.Load($reader)
    $conn.Close()
    return $table
}

function Execute-NonQuery($connectionString, $query) {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    $cmd.ExecuteNonQuery() | Out-Null
    $conn.Close()
}

$localConnStr = "Server=$LocalServer;Database=$LocalDB;User Id=$User;Password=$LocalPassword;"
$remoteConnStr = "Server=$RemoteServer;Database=$RemoteDB;User Id=$User;Password=$RemotePassword;"

# Read data from local table
$selectQuery = "SELECT user_id, user_name, user_email FROM $LocalTable"
$localData = Execute-Query -connectionString $localConnStr -query $selectQuery

$insertedUserIds = @()
$rollbackTriggered = $false

foreach ($row in $localData.Rows) {
    $userId = $row.user_id
    $userName = $row.user_name
    $email = $row.user_email

    if (-not $userId) {
        Write-Host "Skipping insert due to missing or invalid user_id."
        continue
    }

    $insertQuery = "INSERT INTO $RemoteTable (user_id, user_name, user_email) VALUES ('$userId', '$userName', '$email')"

    try {
        Execute-NonQuery -connectionString $remoteConnStr -query $insertQuery
        Write-Host "Inserted user_id: $userId"
        $insertedUserIds += $userId
    }
    catch {
        # Check if error message contains primary key violation
        if ($_.Exception.Message -match "Violation of PRIMARY KEY constraint") {
            Write-Host "Duplicate user_id found: $userId. Triggering rollback."
            $rollbackTriggered = $true
            break
        }
        else {
            Write-Host "Insert failed for user_id: $userId. Reason: $($_.Exception.Message)"
            $rollbackTriggered = $true
            break
        }
    }
}

if ($rollbackTriggered -and $insertedUserIds.Count -gt 0) {
    $userIdsCsv = "'" + ($insertedUserIds -join "','") + "'"
    $deleteQuery = "DELETE FROM $RemoteTable WHERE user_id IN ($userIdsCsv)"
    Write-Host "Rolling back inserted user_ids: $userIdsCsv"
    Execute-NonQuery -connectionString $remoteConnStr -query $deleteQuery
    Write-Host "Rollback completed."
    exit 1
}
elseif (-not $rollbackTriggered) {
    $result = $insertedUserIds -join ','
    Write-Output $result  # output for Jenkins tracking
}

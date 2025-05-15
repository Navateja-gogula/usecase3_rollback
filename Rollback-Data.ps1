param(
    [string]$Server,
    [string]$Database,
    [string]$User,
    [string]$Password,
    [string[]]$UserIdsToRollback  # array of user_ids to delete
)

function Execute-NonQuery($connectionString, $query) {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    $cmd.ExecuteNonQuery() | Out-Null
    $conn.Close()
}

$connectionString = "Server=$Server;Database=$Database;User Id=$User;Password=$Password;"

if ($UserIdsToRollback.Length -eq 0) {
    Write-Host "No user IDs provided to rollback."
    exit 0
}

# Convert array of user_ids to comma separated string for SQL IN clause
$userIdsCsv = $UserIdsToRollback -join "','"
$userIdsCsv = "'$userIdsCsv'"

$query = "DELETE FROM dbo.asp_user WHERE user_id IN ($userIdsCsv)"

Write-Host "Running rollback: Deleting user_ids: $userIdsCsv"
Execute-NonQuery -connectionString $connectionString -query $query
Write-Host "Rollback completed successfully."

function Execute-Query($connectionString, $query) {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    $table = New-Object System.Data.DataTable
    $adapter.Fill($table) | Out-Null
    $conn.Close()
    return $table
}

function Insert-Row($connectionString, $query) {
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    $cmd.ExecuteNonQuery() | Out-Null
    $conn.Close()
}

# Connection strings
$localConn = "Server=10.128.0.16,1433;Database=aspnet_DB;User Id=sa;Password=P@ssword@123;"
$remoteConn = "Server=34.170.77.150;Database=aspnet_DB;User Id=sqlserver;Password=P@ssword@123;"

Write-Host "Fetching data from local SQL Server..."
$data = Execute-Query -connectionString $localConn -query "SELECT user_id, user_name, user_email FROM dbo.asp_user"

foreach ($row in $data) {
    $query = "INSERT INTO asp_user (user_id, user_name, user_email) VALUES ('$($row.user_id)', '$($row.user_name)', '$($row.user_email)')"
    Insert-Row -connectionString $remoteConn -query $query
}

Write-Host " Data copied successfully."

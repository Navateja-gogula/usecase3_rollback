pipeline {
    agent any

    environment {
        LOCAL_SERVER = 'tcp:10.128.0.16,1433'
        REMOTE_SERVER = '34.170.77.150'
        LOCAL_DB = 'aspnet_DB'
        REMOTE_DB = 'aspnet_DB'
        LOCAL_TABLE = 'asp_user'
        REMOTE_TABLE = 'asp_user'
        SA_USER = 'sa'
        SA_PASS = 'P@ssword@123' // Store securely in Jenkins Credentials ideally
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/Navateja-gogula/use_case-3.git', branch: 'main'
            }
        }

        stage('Insert Data to Remote SQL Server') {
            steps {
                powershell '''
                    # Call your existing insert script and capture inserted user_ids for rollback
                    $insertedUserIds = ./Copy-Data.ps1 `
                        -LocalServer "$env:LOCAL_SERVER" `
                        -RemoteServer "$env:REMOTE_SERVER" `
                        -LocalDB "$env:LOCAL_DB" `
                        -RemoteDB "$env:REMOTE_DB" `
                        -LocalTable "$env:LOCAL_TABLE" `
                        -RemoteTable "$env:REMOTE_TABLE" `
                        -User "$env:SA_USER" `
                        -Password "$env:SA_PASS"

                    # Assuming Copy-Data.ps1 outputs inserted user_ids (adjust script if needed)
                    Write-Output "Inserted User IDs: $insertedUserIds"
                    # Save to file or environment variable if you want to pass to rollback
                    Set-Content -Path insertedUserIds.txt -Value $insertedUserIds
                '''
            }
        }

        stage('Rollback on Failure') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                powershell '''
                    # Read inserted user_ids from file
                    $userIds = Get-Content -Path insertedUserIds.txt

                    ./Rollback-Data.ps1 `
                        -Server "$env:REMOTE_SERVER" `
                        -Database "$env:REMOTE_DB" `
                        -User "$env:SA_USER" `
                        -Password "$env:SA_PASS" `
                        -UserIdsToRollback $userIds
                '''
            }
        }
    }

    post {
        failure {
            echo "Build failed. Rollback stage will be triggered if defined."
        }
    }
}

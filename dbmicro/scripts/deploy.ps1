param(
    [string]$ContainerId = "9ea",
    [string]$ProjectRoot = "..",
    [string]$JarName = "practice-0.0.1-SNAPSHOT.jar",
    [string]$TargetPath = "/app/app.jar"
)

Write-Host "=== Starting application deployment ===" -ForegroundColor Green

try {
    # Stop container
    Write-Host "1. Stopping container $ContainerId..." -ForegroundColor Yellow
    docker stop $ContainerId
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Container $ContainerId not found or already stopped"
    }

    # Build Maven project from project root
    Write-Host "2. Building Maven project..." -ForegroundColor Yellow
    Set-Location $ProjectRoot
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed!"
    }

    # Получаем абсолютный путь к JAR файлу после перехода в корень проекта
    $JarPath = Join-Path -Path (Get-Location) -ChildPath "target\$JarName"
    Write-Host "Debug: JAR path = $JarPath" -ForegroundColor Gray

    # Check if JAR file was created
    if (-not (Test-Path $JarPath)) {
        throw "JAR file not found: $JarPath"
    }

    # Copy JAR file to container
    Write-Host "3. Copying JAR file to container..." -ForegroundColor Yellow
    docker cp $JarPath "${ContainerId}:$TargetPath"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy file to container!"
    }

    # Start container
    Write-Host "4. Старт Starting container $ContainerId..." -ForegroundColor Yellow
    docker start $ContainerId
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container!"
    }

    Write-Host "=== Deployment completed successfully! ===" -ForegroundColor Green
    Write-Host "Container $ContainerId is running with updated application" -ForegroundColor Cyan

} catch {
    Write-Error "Error during deployment: $($_.Exception.Message)"
    exit 1
}
param(
    [string]$ProjectId = "college-backend-prod",
    [string]$ServiceName = "pathwise-backend",
    [string]$Region = "asia-south1",
    [string]$ImageName = "pathwise-backend",
    [string]$Category = "MBC",
    [double]$Cutoff = 175,
    [string]$Interest = "Software",
    [string]$District = "",
    [switch]$DeleteService
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Get-ContainerEnvMap {
    param(
        [string]$Service,
        [string]$SvcRegion
    )

    $json = gcloud run services describe $Service --region $SvcRegion --platform managed --format=json 2>$null
    if (-not $json) {
        return $null
    }

    $obj = $json | ConvertFrom-Json
    if (-not $obj.spec.template.spec.containers) {
        return $null
    }

    $envMap = @{}
    foreach ($envItem in $obj.spec.template.spec.containers[0].env) {
        if ($envItem.name -and $envItem.value) {
            $envMap[$envItem.name] = $envItem.value
        }
    }

    return $envMap
}

function Ensure-DeploymentEnv {
    param(
        [hashtable]$EnvMap
    )

    $required = @("DB_NAME", "DB_USER", "DB_PASSWORD")
    foreach ($key in $required) {
        if (-not $EnvMap.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($EnvMap[$key])) {
            throw "Missing required Cloud Run env var: $key"
        }
    }

    # DB_HOST and DB_PORT are required only if CLOUD_SQL_CONNECTION_NAME is NOT present
    if (-not $EnvMap.ContainsKey("CLOUD_SQL_CONNECTION_NAME") -or [string]::IsNullOrWhiteSpace($EnvMap["CLOUD_SQL_CONNECTION_NAME"])) {
        if (-not $EnvMap.ContainsKey("DB_HOST") -or [string]::IsNullOrWhiteSpace($EnvMap["DB_HOST"])) {
            throw "Missing required Cloud Run env var: DB_HOST (required when CLOUD_SQL_CONNECTION_NAME is absent)"
        }
        if (-not $EnvMap.ContainsKey("DB_PORT") -or [string]::IsNullOrWhiteSpace($EnvMap["DB_PORT"])) {
            throw "Missing required Cloud Run env var: DB_PORT (required when CLOUD_SQL_CONNECTION_NAME is absent)"
        }
    } else {
        # If using Cloud SQL, the proxy runs on localhost:5432
        if (-not $EnvMap.ContainsKey("DB_HOST")) { $EnvMap["DB_HOST"] = "127.0.0.1" }
        if (-not $EnvMap.ContainsKey("DB_PORT")) { $EnvMap["DB_PORT"] = "5432" }
    }

    if (-not $EnvMap.ContainsKey("SPRING_PROFILES_ACTIVE")) {
        $EnvMap["SPRING_PROFILES_ACTIVE"] = "prod"
    }

    if (-not $EnvMap.ContainsKey("DB_SSLMODE")) {
        $EnvMap["DB_SSLMODE"] = "prefer"
    }

    # Safe default for production
    $EnvMap["SPRING_JPA_HIBERNATE_DDL_AUTO"] = "none"
    $EnvMap["SPRING_SQL_INIT_MODE"] = "never"

    return $EnvMap
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Step "Building Spring Boot artifact (mvn clean package -DskipTests)"
.\mvnw.cmd clean package -DskipTests

$jarPath = Join-Path $scriptDir "target\backend-0.0.1-SNAPSHOT.jar"
if (-not (Test-Path $jarPath)) {
    throw "Build output not found: $jarPath"
}

Write-Step "Validating Dockerfile"
$dockerfilePath = Join-Path $scriptDir "Dockerfile"
if (-not (Test-Path $dockerfilePath)) {
    throw "Dockerfile not found at $dockerfilePath"
}

$dockerfileText = Get-Content $dockerfilePath -Raw
if ($dockerfileText -notmatch "EXPOSE\s+8080") {
    throw "Dockerfile must expose port 8080"
}
if ($dockerfileText -notmatch "FROM\s+.*(openjdk|temurin|eclipse-temurin)") {
    throw "Dockerfile must use a JDK/OpenJDK/Temurin base image"
}

$imageUri = "gcr.io/$ProjectId/$ImageName"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Step "Building Docker image locally ($imageUri)"
    docker build -t $imageUri .
} else {
    Write-Host "Docker not found locally. Skipping local docker build and using Cloud Build." -ForegroundColor Yellow
}

Write-Step "Submitting Cloud Build ($imageUri)"
gcloud builds submit $scriptDir --tag $imageUri --project $ProjectId

Write-Step "Resolving Cloud Run environment variables"
$envMap = Get-ContainerEnvMap -Service $ServiceName -SvcRegion $Region
if (-not $envMap) {
    Write-Host "No existing service env found in $Region. Trying us-central1 fallback..." -ForegroundColor Yellow
    $envMap = Get-ContainerEnvMap -Service $ServiceName -SvcRegion "us-central1"
}
if (-not $envMap) {
    throw "Could not find existing Cloud Run env config. Set DB_* env vars on service manually, then rerun."
}
$envMap = Ensure-DeploymentEnv -EnvMap $envMap

$setEnvVars = ($envMap.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}={1}" -f $_.Name, $_.Value }) -join ","

if ($DeleteService) {
    Write-Step "Deleting service (cache reset workflow)"
    gcloud run services delete $ServiceName --region $Region --platform managed --quiet --project $ProjectId
}

Write-Step "Deploying Cloud Run revision"
gcloud run deploy $ServiceName `
  --image $imageUri `
  --platform managed `
  --region $Region `
  --allow-unauthenticated `
  --set-env-vars "$setEnvVars" `
  --project $ProjectId

Write-Step "Verifying deployed endpoint"
$serviceUrl = gcloud run services describe $ServiceName --region $Region --platform managed --project $ProjectId --format="value(status.url)"
if (-not $serviceUrl) {
    throw "Failed to resolve deployed service URL"
}

$encodedCategory = [uri]::EscapeDataString($Category)
$encodedInterest = [uri]::EscapeDataString($Interest)
$verifyUrl = "$serviceUrl/api/recommend?category=$encodedCategory&cutoff=$Cutoff&interest=$encodedInterest"
if (-not [string]::IsNullOrWhiteSpace($District)) {
    $encodedDistrict = [uri]::EscapeDataString($District)
    $verifyUrl = "$verifyUrl&district=$encodedDistrict"
}
Write-Host "Verification URL: $verifyUrl" -ForegroundColor Green

try {
    $response = Invoke-RestMethod -Uri $verifyUrl -Method Get -TimeoutSec 30
    if ($response -is [System.Array]) {
        Write-Host "Verification success. Rows returned: $($response.Count)" -ForegroundColor Green
    } else {
        Write-Host "Verification success. Response received." -ForegroundColor Green
    }
} catch {
    Write-Host "Verification failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

Write-Step "Redeployment completed"
Write-Host "Service URL: $serviceUrl" -ForegroundColor Green

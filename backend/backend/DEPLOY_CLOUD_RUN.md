# Cloud Run Redeploy Guide

## One-command automation

Run from `backend/backend`:

```powershell
.\deploy-cloudrun.ps1
```

Optional cache-reset workflow (delete and recreate service):

```powershell
.\deploy-cloudrun.ps1 -DeleteService
```

Optional custom deploy parameters:

```powershell
.\deploy-cloudrun.ps1 -ProjectId college-backend-prod -ServiceName pathwise-backend -Region asia-south1
```

## What the script does

1. `mvn clean package -DskipTests`
2. Validates `Dockerfile` includes:
   - JDK/OpenJDK/Temurin base image
   - `EXPOSE 8080`
3. Runs local `docker build` if Docker exists
4. Runs `gcloud builds submit --tag gcr.io/<PROJECT_ID>/pathwise-backend`
5. Deploys with:
   - `gcloud run deploy ... --allow-unauthenticated`
   - Existing DB env vars reused from current service config
   - Safe startup override: `SPRING_JPA_HIBERNATE_DDL_AUTO=none`
6. Verifies `/api/recommend` endpoint

## Manual commands (if needed)

```powershell
# Build
.\mvnw.cmd clean package -DskipTests

# Build+push container image via Cloud Build
gcloud builds submit . --tag gcr.io/<PROJECT_ID>/pathwise-backend

# Deploy Cloud Run
gcloud run deploy pathwise-backend 
  --image gcr.io/<PROJECT_ID>/pathwise-backend 
  --platform managed 
  --region asia-south1 
  --allow-unauthenticated
```

## Verification

```powershell
# Get URL
gcloud run services describe pathwise-backend --region asia-south1 --format="value(status.url)"

# Test endpoint
Invoke-RestMethod -Uri "<SERVICE_URL>/api/recommend?category=MBC&cutoff=175&interest=Software" -Method Get
```

## Debug checklist

- Build fails:
  - Run `.\mvnw.cmd clean package -DskipTests -e`
- Cloud Build fails:
  - Open build logs from the URL printed by `gcloud builds submit`
- Cloud Run fails to start:
  - `gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pathwise-backend" --limit 100 --order=desc`
- DB connection error (`localhost:5432` in Cloud Run logs):
  - Missing DB env vars on service. Ensure `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` are set.
- Schema validation mismatch in production:
  - Set `SPRING_JPA_HIBERNATE_DDL_AUTO=none` for Cloud Run.
- Stale service state / rollout issue:
  - Use delete-and-redeploy flow:
    - `.\deploy-cloudrun.ps1 -DeleteService`

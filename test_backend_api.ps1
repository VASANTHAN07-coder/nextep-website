#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test PathWise Backend API Endpoints
.DESCRIPTION
    This script tests all the backend API endpoints to verify the backend is working correctly.
#>

$baseUrl = "http://localhost:8080"
$passed = 0
$failed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Body = $null
    )
    
    try {
        Write-Host "`n=== Testing: $Name ===" -ForegroundColor Cyan
        Write-Host "URL: $baseUrl$Endpoint" -ForegroundColor Gray
        
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri "$baseUrl$Endpoint" -Method Get -TimeoutSec 5
        } else {
            $response = Invoke-RestMethod -Uri "$baseUrl$Endpoint" -Method Post `
                -Body ($Body | ConvertTo-Json) `
                -ContentType "application/json" -TimeoutSec 5
        }
        
        Write-Host "✅ PASSED" -ForegroundColor Green
        Write-Host "Response: " -ForegroundColor Gray
        Write-Host ($response | ConvertTo-Json -Depth 2) -ForegroundColor White
        $global:passed++
    }
    catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $global:failed++
    }
}

Write-Host "
╔════════════════════════════════════════════════╗
║    PathWise Backend API Testing Suite          ║
╚════════════════════════════════════════════════╝
" -ForegroundColor Cyan

# Test 1: Health Check
Test-Endpoint -Name "Health Check (Database Connection)" `
    -Method "GET" `
    -Endpoint "/api/test-db"

# Test 2: Get Courses
Test-Endpoint -Name "Get Available Courses" `
    -Method "GET" `
    -Endpoint "/api/courses"

# Test 3: Get College Options (All)
Test-Endpoint -Name "Get All College Options" `
    -Method "GET" `
    -Endpoint "/api/college-options"

# Test 4: Get College Options (Filtered by Course)
Test-Endpoint -Name "Get College Options (Computer Science Engineering)" `
    -Method "GET" `
    -Endpoint "/api/college-options?preferred_course=Computer%20Science%20Engineering"

# Test 5: Get College Options (Filtered by District)
Test-Endpoint -Name "Get College Options (Chennai District)" `
    -Method "GET" `
    -Endpoint "/api/college-options?district=Chennai"

# Test 6: Get Recommendations
Test-Endpoint -Name "Get Recommendations (POST)" `
    -Method "POST" `
    -Endpoint "/api/recommend" `
    -Body @{
        student_cutoff = 190.5
        category = "oc"
        preferred_course = "Computer Science Engineering"
        preferred_colleges = @("Anna University - MIT Campus")
    }

# Test 7: Get Target Colleges
Test-Endpoint -Name "Get Target Colleges (OC Category, Cutoff 190)" `
    -Method "GET" `
    -Endpoint "/api/target-colleges?cutoff=190&community=oc"

# Summary
Write-Host "`n
╔════════════════════════════════════════════════╗
║                  TEST SUMMARY                   ║
╠════════════════════════════════════════════════╣
║  ✅ Passed: $passed
║  ❌ Failed: $failed
╚════════════════════════════════════════════════╝
" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "🎉 All tests passed! Your backend is working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed. Please check the errors above." -ForegroundColor Yellow
    exit 1
}

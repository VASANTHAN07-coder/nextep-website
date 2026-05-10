$base = "https://pathwise-backend-507210518116.asia-south1.run.app"
$users = 100
$timeoutSec = 20

$handler = New-Object System.Net.Http.HttpClientHandler
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds($timeoutSec)

$tasks = @()
for ($i = 1; $i -le $users; $i++) {
    $tasks += [System.Threading.Tasks.Task[object]]::Run([Func[object]]{
        $swUser = [System.Diagnostics.Stopwatch]::StartNew()
        $errors = 0
        $timeouts = 0
        $calls = New-Object System.Collections.Generic.List[double]

        function Invoke-Step {
            param([System.Net.Http.HttpClient]$c, [string]$url, [string]$method)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                if ($method -eq "GET") {
                    $resp = $c.GetAsync($url).GetAwaiter().GetResult()
                } else {
                    throw "Unsupported method"
                }
                $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                $sw.Stop()
                return [PSCustomObject]@{ ok = $resp.IsSuccessStatusCode; status = [int]$resp.StatusCode; ms = $sw.Elapsed.TotalMilliseconds; body = $body; timeout = $false }
            } catch [System.Threading.Tasks.TaskCanceledException] {
                $sw.Stop()
                return [PSCustomObject]@{ ok = $false; status = 0; ms = $sw.Elapsed.TotalMilliseconds; body = ""; timeout = $true }
            } catch {
                $sw.Stop()
                return [PSCustomObject]@{ ok = $false; status = 0; ms = $sw.Elapsed.TotalMilliseconds; body = ""; timeout = $false }
            }
        }

        $r1 = Invoke-Step -c $client -url "$base/api/courses" -method "GET"
        $calls.Add($r1.ms)
        if (-not $r1.ok) { $errors++ }
        if ($r1.timeout) { $timeouts++ }

        $r2 = Invoke-Step -c $client -url "$base/api/districts" -method "GET"
        $calls.Add($r2.ms)
        if (-not $r2.ok) { $errors++ }
        if ($r2.timeout) { $timeouts++ }

        $r3 = Invoke-Step -c $client -url "$base/api/recommend?category=BC&cutoff=198&interest=Computer%20Science%20Engineering" -method "GET"
        $calls.Add($r3.ms)
        if (-not $r3.ok) { $errors++ }
        if ($r3.timeout) { $timeouts++ }

        # PDF generation is client-side in this app (no backend endpoint).
        # Simulate client CPU work to keep user journey shape with a local step.
        $swPdf = [System.Diagnostics.Stopwatch]::StartNew()
        $dummy = New-Object byte[] (512KB)
        [System.Array]::Fill($dummy, [byte]7)
        $hash = [System.Security.Cryptography.SHA256]::HashData($dummy)
        $swPdf.Stop()

        $swUser.Stop()
        return [PSCustomObject]@{
            errors = $errors
            timeouts = $timeouts
            callMs = $calls
            pdfMs = $swPdf.Elapsed.TotalMilliseconds
            userMs = $swUser.Elapsed.TotalMilliseconds
        }
    })
}

[System.Threading.Tasks.Task]::WaitAll($tasks)

$all = $tasks | ForEach-Object { $_.Result }
$apiTimes = @($all | ForEach-Object { $_.callMs } )
$apiCalls = $apiTimes.Count
$errorCount = ($all | Measure-Object -Property errors -Sum).Sum
$timeoutCount = ($all | Measure-Object -Property timeouts -Sum).Sum

$sorted = $apiTimes | Sort-Object
$avg = ($apiTimes | Measure-Object -Average).Average
$max = ($apiTimes | Measure-Object -Maximum).Maximum
$min = ($apiTimes | Measure-Object -Minimum).Minimum
$p50 = $sorted[[math]::Floor(($sorted.Count - 1) * 0.50)]
$p95 = $sorted[[math]::Floor(($sorted.Count - 1) * 0.95)]
$p99 = $sorted[[math]::Floor(($sorted.Count - 1) * 0.99)]
$errorRate = if ($apiCalls -eq 0) { 100.0 } else { [math]::Round(($errorCount / $apiCalls) * 100.0, 3) }
$timeoutRate = if ($apiCalls -eq 0) { 100.0 } else { [math]::Round(($timeoutCount / $apiCalls) * 100.0, 3) }

$pdfAvg = ($all | Measure-Object -Property pdfMs -Average).Average
$userAvg = ($all | Measure-Object -Property userMs -Average).Average

[PSCustomObject]@{
    users = $users
    apiCalls = $apiCalls
    errorCount = $errorCount
    timeoutCount = $timeoutCount
    errorRatePct = $errorRate
    timeoutRatePct = $timeoutRate
    minMs = [math]::Round($min,2)
    p50Ms = [math]::Round($p50,2)
    p95Ms = [math]::Round($p95,2)
    p99Ms = [math]::Round($p99,2)
    avgMs = [math]::Round($avg,2)
    maxMs = [math]::Round($max,2)
    avgPdfStepMs = [math]::Round($pdfAvg,2)
    avgUserJourneyMs = [math]::Round($userAvg,2)
} | ConvertTo-Json -Depth 4

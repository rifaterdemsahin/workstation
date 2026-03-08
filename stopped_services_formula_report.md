# Stopped Automatic Services - Formula Report

**Report Date:** 2026-03-08
**Machine:** Pexabo
**Branch:** main

---

## Executive Summary

**Total Stopped Automatic Services:** 8

**Service Health Score:** `(Total Services - Stopped Services) / Total Services × 100`

---

## Service Analysis

| # | Service Name | Category | Priority | Risk Level |
|---|--------------|----------|----------|------------|
| 1 | Microsoft Edge Update Service (edgeupdate) | Update Management | Low | Low |
| 2 | Google Updater Internal Service | Update Management | Low | Low |
| 3 | Google Updater Service | Update Management | Low | Low |
| 4 | Downloaded Maps Manager | User Experience | Low | Low |
| 5 | Realtek Bluetooth Device Manager Service | Hardware Management | Medium | Medium |
| 6 | Software Protection | Licensing/Activation | High | High |
| 7 | Windows Image Acquisition (WIA) | Hardware Support | Medium | Medium |
| 8 | Windows Biometric Service | Security/Authentication | High | High |

---

## Formulas & Metrics

### 1. Service Health Ratio
```
Service Health % = (Active Auto Services / Total Auto Services) × 100
```

### 2. Risk Score Calculation
```
Total Risk Score = Σ(Service Risk Level)
Where:
- High Risk = 3 points
- Medium Risk = 2 points
- Low Risk = 1 point

Current Risk Score = (2 × 3) + (2 × 2) + (4 × 1) = 14 points
```

### 3. Category Distribution
```
Update Management Services: 3/8 (37.5%)
Hardware Management Services: 2/8 (25%)
Security Services: 1/8 (12.5%)
System Services: 1/8 (12.5%)
User Experience: 1/8 (12.5%)
```

### 4. Impact Assessment Formula
```
Impact Score = (Priority Level × Usage Frequency) + (Dependencies Count × 2)
```

---

## Critical Services Requiring Attention

### High Priority (Risk Level: High)

#### 1. Software Protection
- **Function:** Windows activation and licensing
- **Impact:** May affect system activation status
- **Recommendation:** Investigate if system is properly activated
- **Action:** `Start-Service sppsvc` or verify activation status

#### 2. Windows Biometric Service
- **Function:** Fingerprint/facial recognition authentication
- **Impact:** Biometric login features unavailable
- **Recommendation:** Start if using Windows Hello or biometric devices
- **Action:** `Start-Service WbioSrvc`

### Medium Priority (Risk Level: Medium)

#### 3. Realtek Bluetooth Device Manager
- **Function:** Bluetooth hardware management
- **Impact:** Bluetooth connectivity may be degraded
- **Recommendation:** Start if using Bluetooth devices
- **Action:** `Start-Service "Realtek Bluetooth Device Manager Service"`

#### 4. Windows Image Acquisition (WIA)
- **Function:** Scanner and camera support
- **Impact:** Scanners/cameras may not function
- **Recommendation:** Start if using imaging devices
- **Action:** `Start-Service stisvc`

---

## Automated Remediation Script

```powershell
# Service Health Check and Auto-Start Script

$criticalServices = @(
    "sppsvc",           # Software Protection
    "WbioSrvc"          # Windows Biometric Service
)

$optionalServices = @(
    "stisvc",           # Windows Image Acquisition
    "Realtek Bluetooth Device Manager Service"
)

# Function to check and start service
function Start-StoppedAutoService {
    param($ServiceName)

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($service -and $service.StartType -eq "Automatic" -and $service.Status -eq "Stopped") {
        try {
            Start-Service -Name $ServiceName
            Write-Host "Started: $($service.DisplayName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to start: $($service.DisplayName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Start critical services
Write-Host "`nStarting Critical Services..." -ForegroundColor Yellow
foreach ($service in $criticalServices) {
    Start-StoppedAutoService -ServiceName $service
}

# Optionally start other services (prompt user)
Write-Host "`nOptional Services Available" -ForegroundColor Cyan
foreach ($service in $optionalServices) {
    $response = Read-Host "Start $service? (Y/N)"
    if ($response -eq 'Y') {
        Start-StoppedAutoService -ServiceName $service
    }
}
```

---

## Service Optimization Recommendations

### Formula: Service Startup Optimization Score
```
Optimization Score = (Unnecessary Auto Services / Total Auto Services) × 100

Target: < 20% for optimal performance
```

### Services Safe to Disable (Set to Manual)

1. **Microsoft Edge Update Service** - Only needed if using Edge browser
2. **Google Updater Services** - Only needed if using Chrome/Google apps
3. **Downloaded Maps Manager** - Only needed if using offline maps

**PowerShell Command to Set to Manual:**
```powershell
Set-Service -Name "edgeupdate" -StartupType Manual
Set-Service -Name "GoogleUpdaterInternalService147.0.7703.0" -StartupType Manual
Set-Service -Name "GoogleUpdaterService147.0.7703.0" -StartupType Manual
Set-Service -Name "MapsBroker" -StartupType Manual
```

---

## Monitoring Formula

### Ongoing Service Health Monitoring
```powershell
# Daily health check formula
$healthCheck = {
    $total = (Get-Service | Where-Object {$_.StartType -eq "Automatic"}).Count
    $stopped = (Get-Service | Where-Object {$_.StartType -eq "Automatic" -and $_.Status -eq "Stopped"}).Count
    $healthPercent = [math]::Round((($total - $stopped) / $total) * 100, 2)

    [PSCustomObject]@{
        Date = Get-Date -Format "yyyy-MM-dd HH:mm"
        TotalAutoServices = $total
        StoppedServices = $stopped
        HealthPercentage = $healthPercent
        Status = if ($healthPercent -ge 95) { "Healthy" }
                 elseif ($healthPercent -ge 85) { "Warning" }
                 else { "Critical" }
    }
}

& $healthCheck
```

---

## Key Performance Indicators (KPIs)

| Metric | Formula | Current Value | Target | Status |
|--------|---------|---------------|--------|--------|
| Service Availability | Active/Total × 100 | Calculate manually | ≥ 95% | TBD |
| Critical Service Uptime | Critical Active/Critical Total × 100 | 0/2 (0%) | 100% | ⚠ |
| Medium Priority Uptime | Medium Active/Medium Total × 100 | 0/2 (0%) | ≥ 80% | ⚠ |
| Low Priority Services | Low Stopped/Low Total × 100 | 4/4 (100%) | Any | ✓ |

---

## Next Steps

1. ✅ Review critical services (Software Protection, Biometric)
2. ⚠ Start high-priority services if features are needed
3. 📊 Run health monitoring script daily
4. 🔧 Optimize startup configuration for unused services
5. 📝 Document service dependencies and requirements

---

## References

- Service Name Mappings: C:\Windows\System32\services.msc
- Event Logs: Application and System logs for service failures
- Performance Impact: Task Manager → Startup tab

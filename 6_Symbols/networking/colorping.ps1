# Define the target IP address
$Target = "1.1.1.1"

# Create a Ping object
$ping = New-Object System.Net.NetworkInformation.Ping

# Initialize an array to store response times
$responseTimes = @()

# Infinite loop to continuously ping
while ($true) {
    try {
        # Send a ping and measure the round-trip time
        $reply = $ping.Send($Target)
        $time = $reply.RoundtripTime

        # Add the response time to the array
        $responseTimes += $time

        # Calculate the average response time
        $average = [math]::Round(($responseTimes | Measure-Object -Average).Average, 2)

        # Determine the color based on response time
        if ($reply.Status -eq "Success") {
            if ($time -lt 50) {
                Write-Host "Reply from ${Target}: time=${time}ms (Avg: ${average}ms)" -ForegroundColor Green
            } elseif ($time -lt 100) {
                Write-Host "Reply from ${Target}: time=${time}ms (Avg: ${average}ms)" -ForegroundColor Yellow
            } else {
                Write-Host "Reply from ${Target}: time=${time}ms (Avg: ${average}ms)" -ForegroundColor Red
            }
        } else {
            Write-Host "Ping failed: $($reply.Status)" -ForegroundColor DarkRed
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor DarkRed
    }

    # Wait for 1 second before the next ping
    Start-Sleep -Seconds 1
}

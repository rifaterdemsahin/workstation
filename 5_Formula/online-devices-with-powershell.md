💻 C:\Users\Pexabo 🌳 main
> 1..254 | ForEach-Object { $ip = "192.168.0.$_"; if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) { Write-Host "$ip is UP" -ForegroundColor Green } }
192.168.0.1 is UP
192.168.0.34 is UP
192.168.0.75 is UP
192.168.0.96 is UP
192.168.0.107 is UP
192.168.0.109 is UP
192.168.0.132 is UP
192.168.0.151 is UP
192.168.0.152 is UP
192.168.0.195 is UP
192.168.0.211 is UP
192.168.0.216 is UP
192.168.0.222 is UP
192.168.0.239 is UP
192.168.0.240 is UP
192.168.0.251 is UP
💻 C:\Users\Pexabo 🌳 main
>


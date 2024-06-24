# Đặt tên service và ngưỡng CPU
$serviceName = "MSSQL`$SQLEXPRESS"  # Thay thế bằng tên dịch vụ SQL Server của bạn
$cpuThreshold = 2  # Ngưỡng CPU
$samplePeriod = 30  # Thời gian lấy mẫu (giây)

# Hàm để lấy mức sử dụng CPU hiện tại
function Get-CPUUsage {
    $cpuLoad = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    return [int]$cpuLoad
}

# Biến để lưu trữ thời gian bắt đầu theo dõi và trạng thái theo dõi
$startTime = Get-Date
$exceeding = $false

# Vòng lặp kiểm tra mức sử dụng CPU
while ($true) {
    $cpuUsage = Get-CPUUsage
    Write-Host "Current CPU Usage: $cpuUsage%"

    if ($cpuUsage -ge $cpuThreshold) {
        if (-not $exceeding) {
            $startTime = Get-Date
            $exceeding = $true
        }

        $currentTime = Get-Date
        $elapsedTime = ($currentTime - $startTime).TotalSeconds
        Write-Host "CPU usage has been exceeding $cpuThreshold% for $elapsedTime seconds."

        if ($elapsedTime -ge $samplePeriod) {
            Write-Host "SQL Server CPU usage exceeded $cpuThreshold% for $samplePeriod seconds. Restarting service..."
            Restart-Service -Name $serviceName
            Write-Host "SQL Server service restarted."
            break
        }
    } else {
        # Nếu CPU usage dưới ngưỡng trong lúc theo dõi, dừng kiểm tra và không thực hiện restart
        if ($exceeding) {
            Write-Host "CPU usage dropped below $cpuThreshold%. Stopping monitoring."
            break
        }
    }

    # Chờ 1 giây trước khi kiểm tra lại
    Start-Sleep -Seconds 1
}
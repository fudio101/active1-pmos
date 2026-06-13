$ErrorActionPreference = 'SilentlyContinue'
$c = New-Object System.Net.Sockets.TcpClient
$c.Connect('172.16.42.1', 23)
$s = $c.GetStream(); $s.ReadTimeout = 2500
$buf = New-Object byte[] 16384
function Drain { $sb = New-Object System.Text.StringBuilder; try { while ($true) { $n = $s.Read($buf,0,$buf.Length); if ($n -le 0) { break }; [void]$sb.Append([Text.Encoding]::ASCII.GetString($buf,0,$n)) } } catch {}; return ($sb.ToString() -replace "[\xFF\xFB-\xFE].", '' -replace "[^\x09\x0A\x0D\x20-\x7E]", '') }
function Cmd($t) { $b = [Text.Encoding]::ASCII.GetBytes($t + "`n"); $s.Write($b,0,$b.Length); $s.Flush(); return Drain }
Drain | Out-Null
Write-Output "===== RAM ====="; Cmd 'grep MemTotal /proc/meminfo'
Write-Output "===== CPU cores ====="; Cmd 'nproc; grep -c ^processor /proc/cpuinfo'
Write-Output "===== power_supply (battery/charger) ====="; Cmd 'ls /sys/class/power_supply/ 2>/dev/null'
Write-Output "===== i2c devices (touch?) ====="; Cmd 'ls /sys/bus/i2c/devices/ 2>/dev/null; echo ---; for d in /sys/bus/i2c/devices/*/name; do echo "$d: $(cat $d 2>/dev/null)"; done 2>/dev/null'
Write-Output "===== drm / framebuffer ====="; Cmd 'ls /sys/class/drm/ 2>/dev/null; echo ---; cat /sys/class/graphics/fb0/virtual_size 2>/dev/null'
Write-Output "===== regulators on (count) ====="; Cmd 'dmesg | grep -ic regulator'
Write-Output "===== net interfaces (wifi?) ====="; Cmd 'ls /sys/class/net/ 2>/dev/null'
$c.Close(); Write-Output "===== END ====="

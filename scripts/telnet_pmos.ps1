$ErrorActionPreference = 'SilentlyContinue'
$c = New-Object System.Net.Sockets.TcpClient
$c.Connect('172.16.42.1', 23)
$s = $c.GetStream()
$s.ReadTimeout = 2500
$buf = New-Object byte[] 16384

function Drain {
  $sb = New-Object System.Text.StringBuilder
  try { while ($true) { $n = $s.Read($buf, 0, $buf.Length); if ($n -le 0) { break }; [void]$sb.Append([Text.Encoding]::ASCII.GetString($buf, 0, $n)) } } catch {}
  # strip telnet IAC bytes (0xFF...) roughly + non-printable
  return ($sb.ToString() -replace "[\xFF\xFB-\xFE].", '' -replace "[^\x09\x0A\x0D\x20-\x7E]", '')
}
function Cmd($t) {
  $b = [Text.Encoding]::ASCII.GetBytes($t + "`n")
  $s.Write($b, 0, $b.Length); $s.Flush()
  return Drain
}

Write-Output "===== BANNER ====="
Drain
Write-Output "===== uname ====="
Cmd 'uname -a'
Write-Output "===== /proc/partitions (storage!) ====="
Cmd 'cat /proc/partitions'
Write-Output "===== mmc host + block devices ====="
Cmd 'ls /sys/class/mmc_host; echo ---; ls /sys/block'
Write-Output "===== dmesg: mmc/sdhci/ufs ====="
Cmd 'dmesg | grep -iE "mmc|sdhci|ufs" | tail -25'
Write-Output "===== dmesg: usb/error/fail ====="
Cmd 'dmesg | grep -iE "error|fail|panic" | tail -20'
$c.Close()
Write-Output "===== END ====="

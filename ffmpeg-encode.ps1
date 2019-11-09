function encode {
  param(
    [string]$file,
    [string]$plate,
    [string]$ss,
    [string]$t,
    [int]$scale = 720,
    [string]$codec = "libx264",
    [string]$vf,
    [int]$crf = 23,
    [string[]]$copy = @(),
    [string]$preset = "medium",
    [switch]$smartblur
    )

  if (-Not (Test-Path "$file.mp4")) {
      Write-Host "Missing $file"
      return
  }
  
  $ARGS = "-n -i $file.mp4"
  if (($t -ne "") -or ($ss -ne "")) {
      if ($ss -match '^(\d*):(\d+)$') {
          $ss = [int]$Matches[1] * 60 + [int]$Matches[2];
      } else {
          $ss = [int]$ss;
      }

      if ($t -match '^(\d*):(\d+)$') {
          $t = [int]$Matches[1] * 60 + [int]$Matches[2];
          $t = $t - $ss;
      }

      $ARGS += " -ss $ss"
      if ($t -ne "") {
          $ARGS += " -t $t"
      }
  }

  $ofile = "${file}_${ss}_${plate}.mp4"

  if (Test-Path $ofile) {
    if ((Get-Item $ofile).Length -ne 0) {
      Write-Host "Skip $ofile"
      return
    } else {
      Remove-Item $ofile
    }
  }
  
  $ARGS += " -c:v $codec"
  $ARGS += " -preset $preset"
  $ARGS += " -crf $crf"
  if ($vf -ne "") {
      $vf = $vf + ","
  }
  if ($smartblur) {
      $vf = "smartblur=lr=2.00:ls=-0.90:lt=-5.0:cr=0.5:cs=1.0:ct=1.5, $vf"
  }
  $ARGS += " -an -vf `"scale=-1:$scale, $vf ass=$file.ssa`""
  
  $ARGS += " $ofile"

  
  Write-Host "Encode ${ofile}: $ARGS"
  Start-Process -FilePath "C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe" `
      -NoNewWindow -Wait `
      -ArgumentList $ARGS

  # $copy.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
  foreach ($c in $copy) {
      Write-Host "Copy to ${file}_${ss}_${c}.mp4"
      Copy-Item $ofile -Destination "${file}_${ss}_${c}.mp4"
 }

  #   -n -i %FILE%.mp4 -ss %SS% -t %T% -c:v libx264 -preset medium -crf 21 -an -vf "scale=-1:720, ass=%FILE%.ssa" %FILE%_%SS%_%PLATE%.mp4
}

function pause {
  Write-Host -NoNewLine 'Press any key to continue...';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function TagTime {
  $mediaCreatedCol = -1;
  $lengthCol = -1;

  $shell = New-Object -COMObject Shell.Application
  $folder = (Get-Item -Path ".\").FullName
  $shellfolder = $shell.Namespace($folder)
  $shellfile = $shellfolder.ParseName($file)
  0..287 | Foreach-Object {
      # '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_)
      if ($shellfolder.GetDetailsOf($null, $_) -eq 'Length') {
          $lengthCol = $_;
      } elseif ($shellfolder.GetDetailsOf($null, $_) -eq 'Media created') {
          $mediaCreatedCol = $_;
      }
  }

}

function encodeJpg {
  param(
    [string]$file,
    [string]$plate
    )

  $dateTakenCol = -1;

  $shell = New-Object -COMObject Shell.Application
  $folder = (Get-Item -Path ".\").FullName
  $shellfolder = $shell.Namespace($folder)
  $shellfile = $shellfolder.ParseName($file)
  0..287 | Foreach-Object {
      # '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_)
      if ($shellfolder.GetDetailsOf($null, $_) -eq 'Date taken') {
          $dateTakenCol = $_;
      }
  }
}

# "ffmpeg.exe"  -n -f image2 -i %FILE%.jpg %FILE%.mp4
# "ffmpeg.exe"  -n -i %FILE%.mp4 -c:v libx264 -preset medium -crf 21 -an -vf "ass=%FILE%.ssa" %FILE%_0.mp4


# Set-ExecutionPolicy Bypass -Scope Process

# Usage:
# . ../ffmpeg-encode.ps1
# encode PREFIX PLATE START END -scale -1

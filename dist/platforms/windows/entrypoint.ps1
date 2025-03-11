Get-Process

# Import any necessary registry keys, ie: location of windows 10 sdk
# No guarantee that there will be any necessary registry keys, ie: tvOS
Get-ChildItem -Path c:\regkeys -File | ForEach-Object { reg import $_.fullname }

# Register the Visual Studio installation so Unity can find it
regsvr32 C:\ProgramData\Microsoft\VisualStudio\Setup\x64\Microsoft.VisualStudio.Setup.Configuration.Native.dll

# Kill the regsvr process
Get-Process -Name regsvr32 | ForEach-Object { Stop-Process -Id $_.Id -Force }

# Setup Git Credentials
. "c:\steps\set_gitcredential.ps1"

# Activate Unity
if ($env:SKIP_ACTIVATION -ne "true") {
  $maxRetries = 3
  $retryCount = 0
  do {
    . "c:\steps\activate.ps1"
    if ($ACTIVATION_EXIT_CODE -eq 0) {
      break
    }
    $retryCount++
    Write-Warning "Activation failed with exit code $ACTIVATION_EXIT_CODE. Retrying ($retryCount/$maxRetries)..."
    Start-Sleep -Seconds 5
  } while ($retryCount -lt $maxRetries)

  # If we didn't activate successfully, exit with the exit code from the activation step.
  if ($ACTIVATION_EXIT_CODE -ne 0) {
    Write-Error "Unity activation failed after $maxRetries attempts with exit code $ACTIVATION_EXIT_CODE"
    exit 1 # exit code 1 is failure on windows
  }
}
else {
  Write-Host "Skipping activation"
}

# Build the project
. "c:\steps\build.ps1"

# Free the seat for the activated license
if ($env:SKIP_ACTIVATION -ne "true") {
  . "c:\steps\return_license.ps1"
}

Get-Process

exit $BUILD_EXIT_CODE

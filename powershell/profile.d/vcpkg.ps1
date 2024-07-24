$DefaultVcPkgRot = "W:\microsoft\vcpkg"
if (!$env:VCPKG_ROOT) {
  if(Test-Path $DefaultVcPkgRot) {
    $env:VCPKG_ROOT = $DefaultVcPkgRot
  }
}

if ($env:VCPKG_ROOT) {
  $vcpkg_exe = Join-Path $env:VCPKG_ROOT "vcpkg.exe"
  if (Test-Path $vcpkg_exe) {
    $env:PATH="$env:VCPKG_ROOT;$env:PATH"
  }
}
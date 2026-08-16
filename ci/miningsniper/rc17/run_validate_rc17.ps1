param(
  [Parameter(Mandatory)][string]$Rc16Path,
  [Parameter(Mandatory)][string]$Rc17Path,
  [Parameter(Mandatory)][string]$Rc16ValidationPath,
  [Parameter(Mandatory)][string]$ResultPath
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$started=[DateTimeOffset]::UtcNow.ToString('o')
try{
  & (Join-Path $PSScriptRoot 'validate_rc17.ps1') -Rc16Path $Rc16Path -Rc17Path $Rc17Path -Rc16ValidationPath $Rc16ValidationPath -ResultPath $ResultPath
  if($LASTEXITCODE-ne0){throw ('validate_rc17.ps1 returned '+$LASTEXITCODE)}
  if(-not(Test-Path -LiteralPath $ResultPath)){throw 'validator returned success without receipt'}
  $r=Get-Content -Raw -LiteralPath $ResultPath|ConvertFrom-Json
  if([string]$r.status-ne'PASS'){throw 'validator receipt is not PASS'}
  Write-Host 'RC17_VALIDATOR_WRAPPER_PASS'
}catch{
  $fail=[ordered]@{
    schema='miningsniper-rc17-prechat-validation/v1'
    status='FAIL'
    started_utc=$started
    completed_utc=[DateTimeOffset]::UtcNow.ToString('o')
    powershell=$PSVersionTable.PSVersion.ToString()
    rc17_sha256=if(Test-Path -LiteralPath $Rc17Path){(Get-FileHash -Algorithm SHA256 -LiteralPath $Rc17Path).Hash.ToLowerInvariant()}else{$null}
    error_message=$_.Exception.Message
    exception_type=$_.Exception.GetType().FullName
    script_stack=$_.ScriptStackTrace
    position=$_.InvocationInfo.PositionMessage
    user_host_touched=$false
  }
  $fail|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $ResultPath -Encoding utf8
  Write-Error ('RC17_PRECHAT_FAIL: '+$_.Exception.Message)
  exit 1
}

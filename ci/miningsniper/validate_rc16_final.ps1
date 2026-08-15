param([Parameter(Mandatory)][string]$MainPath,[Parameter(Mandatory)][string]$ResultPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$raw=Get-Content -Raw -LiteralPath $MainPath
$sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $MainPath).Hash.ToLowerInvariant()
$first=($raw -split "`r?`n"|Where-Object{-not[string]::IsNullOrWhiteSpace($_)}|Select-Object -First 1).Trim()
if(-not$first.StartsWith('param(')){throw ('MAIN_PARAM_FIRST_FAIL: '+$first)}
if(-not$raw.Contains('GPU_LANE_R065_RC16')){throw 'RC16 release identity missing'}
if($raw.Contains('GPU_LANE_R065_RC15')){throw 'stale GPU_LANE_R065_RC15 identity remains'}

$tok=$null;$err=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($MainPath,[ref]$tok,[ref]$err)
if($err.Count-gt0){
  foreach($e in $err){Write-Host ('PARSER_ERROR '+$e.ErrorId+' line='+$e.Extent.StartLineNumber+' col='+$e.Extent.StartColumnNumber+' text=['+$e.Extent.Text+'] '+$e.Message)}
  throw ('MAIN_PARSE_FAIL count='+$err.Count)
}

function Get-ConstantPayload([string]$Name){
  $a=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.AssignmentStatementAst]},$true)|Where-Object{
    $_.Left-is[Management.Automation.Language.VariableExpressionAst] -and $_.Left.VariablePath.UserPath-eq$Name
  }|Select-Object -First 1)
  if($a.Count-ne1){throw ('PAYLOAD_ASSIGNMENT_MISSING '+$Name)}
  if($a[0].Right-isnot[Management.Automation.Language.StringConstantExpressionAst]){throw ('PAYLOAD_NOT_CONSTANT '+$Name)}
  return [string]$a[0].Right.Value
}

$supervisor=Get-ConstantPayload 'script:SupervisorPayload'
$duty=Get-ConstantPayload 'script:DutyFixturePayload'
$stop=Get-ConstantPayload 'script:StopPayload'
$status=Get-ConstantPayload 'script:StatusPayload'
$export=Get-ConstantPayload 'script:ExportPayload'

$payloadAsts=@{}
foreach($pair in @(@('supervisor',$supervisor),@('duty',$duty),@('stop',$stop),@('status',$status),@('export',$export))){
  $pt=$null;$pe=$null;$pa=[Management.Automation.Language.Parser]::ParseInput([string]$pair[1],[ref]$pt,[ref]$pe)
  if($pe.Count-gt0){throw (($pair[0].ToUpperInvariant())+'_PARSE_FAIL: '+(($pe|ForEach-Object{$_.Message})-join'; '))}
  $payloadAsts[$pair[0]]=$pa
}
$sa=$payloadAsts['supervisor'];$da=$payloadAsts['duty']
$dutyFirst=($duty -split "`r?`n"|Where-Object{-not[string]::IsNullOrWhiteSpace($_)}|Select-Object -First 1).Trim()
if(-not$dutyFirst.StartsWith('param(')){throw ('DUTY_PARAM_FIRST_FAIL: '+$dutyFirst)}

foreach($name in @('Get-DutySchedule','Invoke-DutyWindow')){
  $sf=@($sa.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]},$true)|Where-Object{$_.Name-eq$name}|Select-Object -First 1)
  $df=@($da.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]},$true)|Where-Object{$_.Name-eq$name}|Select-Object -First 1)
  if($sf.Count-ne1-or$df.Count-ne1){throw ('DUTY_FUNCTION_MISSING '+$name)}
  $sn=($sf[0].Extent.Text-replace'\s+',' ').Trim();$dn=($df[0].Extent.Text-replace'\s+',' ').Trim()
  if($sn-ne$dn){throw ('DUTY_FUNCTION_DRIFT '+$name)}
}

# Permanent custom symbol closure copied from the release's own current contract.
$definedFnNames=@($sa.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]},$true)|ForEach-Object{$_.Name})
$internalExact=@('Parse-Num','Find-NvidiaSmi','Get-NvidiaRow','Get-ForegroundEnginePct','Get-HeartbeatMs','Get-LolApi','Convert-LolApiHashrateMhs','Parse-LolHashrateLine','Get-LolHashrateObservation','Get-NativeLogTail','Get-NetworkState','Test-Pool20128','Start-Miner','Attach-DutyController','Stop-Miner','Day-Dirs','Start-Segment','Close-Segment','Add-Row','Write-Health','Run-ProductiveBootstrap','Get-DutySchedule','Invoke-DutyWindow','Run-DutyCycle','Median','Average','Get-LineCount','Get-LinesSince','Get-FreshLogHashratesSince','Start-GpuSampler','Stop-GpuSampler','Parse-SamplerRowsSince','Get-ApiEtchashSnapshot','Measure-DutyPhase','Start-LearningStage','Pass-LearningStage','Write-LearningState')
$missing=[Collections.Generic.List[string]]::new()
foreach($ca in @($sa.FindAll({param($n)$n-is[Management.Automation.Language.CommandAst]},$true))){
  $name=$ca.GetCommandName();if([string]::IsNullOrWhiteSpace($name)){continue}
  if(($internalExact-contains$name)-and-not($definedFnNames-contains$name)){if(-not$missing.Contains($name)){$missing.Add($name)}}
}
if($missing.Count-gt0){throw ('CUSTOM_SYMBOL_CLOSURE_FAIL '+(($missing|Sort-Object)-join','))}

$reserved=@('PID','PSScriptRoot','PSCommandPath','MyInvocation','ExecutionContext','Host','HOME','PSHOME','PSVersionTable','ShellId','NestedPromptLevel','Error','Args','Input','Matches','OFS','PWD','StackTrace','This')
$bad=[Collections.Generic.List[string]]::new()
foreach($tree in @($ast,$sa,$payloadAsts['stop'],$payloadAsts['status'],$payloadAsts['export'])){
  foreach($p in @($tree.FindAll({param($n)$n-is[Management.Automation.Language.ParameterAst]},$true))){$n=[string]$p.Name.VariablePath.UserPath;if($reserved-contains$n){$bad.Add($n)}}
}
if($bad.Count-gt0){throw ('PARAM_STATE_COLLISION '+(($bad|Sort-Object -Unique)-join','))}
if($supervisor-match'(?i)(?<!script:)\$duty\.(Suspend|Resume|SuspendedThreadCount)'){throw 'RC13_UNQUALIFIED_DUTY_REMAINS'}
if($supervisor-match'(?i)function\s+Measure-DutyPhase\s*\(\s*\[double\]\$Duty(?:\W|$)'){throw 'RC13_DUTY_PARAMETER_COLLISION_REMAINS'}
if($supervisor.Contains('[Math]::Min(1,$Target)')){throw 'RC14_MIXED_NUMERIC_EXPRESSION_REMAINS'}
if($supervisor.Contains('Get-LolHashrateFromLog')){throw 'RC10_REMOVED_SYMBOL_REMAINS'}

$tmp=Join-Path ([IO.Path]::GetTempPath()) ('ms_rc16_final_'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmp)|Out-Null
try{
  $dutyPath=Join-Path $tmp 'DUTY_BEHAVIOR_EXACT_SELFTEST.ps1';$dutyResult=Join-Path $tmp 'DUTY_RESULT.json'
  Set-Content -LiteralPath $dutyPath -Value $duty -Encoding utf8
  $do=@(& $dutyPath -ResultPath $dutyResult)
  if($do-notcontains'DUTY_BEHAVIOR_EXACT_SELFTEST_PASS'){throw 'DUTY_EXEC_MARKER_MISSING'}
  $dr=Get-Content -Raw -LiteralPath $dutyResult|ConvertFrom-Json
  if($dr.status-ne'PASS'){throw 'DUTY_RESULT_NOT_PASS'}
  if($dr.rc14_old_active_ms.d10-ne0-or$dr.rc14_old_active_ms.d25-ne0-or$dr.rc14_old_active_ms.d40-ne0){throw 'RC14_ZERO_REPRO_MISMATCH'}
  if($dr.repaired_schedule_active_ms.'0.1'-ne200-or$dr.repaired_schedule_active_ms.'0.25'-ne500-or$dr.repaired_schedule_active_ms.'0.4'-ne800){throw 'REPAIRED_SCHEDULE_MISMATCH'}

  $apiFn=@($sa.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq'Convert-LolApiHashrateMhs'},$true)|Select-Object -First 1)
  $logFn=@($sa.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq'Parse-LolHashrateLine'},$true)|Select-Object -First 1)
  if($apiFn.Count-ne1-or$logFn.Count-ne1){throw 'HASHRATE_FUNCTION_EXTRACTION_FAIL'}
  $apiFixture=[pscustomobject]@{ok=$true;data=[pscustomobject]@{Algorithms=@([pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239})}}
  # Materialize exact functions into current scope without a second generated script.
  . ([scriptblock]::Create($apiFn[0].Extent.Text))
  . ([scriptblock]::Create($logFn[0].Extent.Text))
  $a=Convert-LolApiHashrateMhs $apiFixture
  if($null-eq$a-or[Math]::Abs([double]$a-12.352733907856239)-gt0.000001){throw ('API_FIXTURE_FAIL '+[string]$a)}
  $l=Parse-LolHashrateLine '07:10:26 Average speed (5s): 17.89 Mh/s'
  if($null-eq$l-or[Math]::Abs([double]$l-17.89)-gt0.000001){throw ('LOG_FIXTURE_FAIL '+[string]$l)}

  [ordered]@{status='PASS';powershell=$PSVersionTable.PSVersion.ToString();artifact_sha256=$sha;main_parse='PASS';payload_parse='PASS';duty_param_first='PASS';duty_function_parity='PASS';custom_symbol_closure='PASS';parameter_collision_scan='PASS';rc13_scope_guard='PASS';rc14_numeric_guard='PASS';hashrate_fixture='PASS';duty_fixture='PASS';rc14_old_active_ms=$dr.rc14_old_active_ms;repaired_active_ms=$dr.repaired_schedule_active_ms;timing=$dr.fake_controller_timing}|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $ResultPath -Encoding utf8
  Write-Host 'FINAL_RC16_EXACT_ARTIFACT_GATE_PASS'
}finally{Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue}

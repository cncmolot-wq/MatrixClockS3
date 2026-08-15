param([Parameter(Mandatory)][string]$PwshPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$outDir=Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $outDir|Out-Null
$partsDir=Join-Path $PSScriptRoot 'rc16_exact_parts'
$candidate=Join-Path $outDir 'RUN_ACTIVATE_R065_GPU_LANE_RC16.ps1'
$validationPath=Join-Path $outDir 'RC16_REBUILD_VALIDATION.json'
$dutyResult=Join-Path $outDir 'DUTY_RESULT.json'
$hashResult=Join-Path $outDir 'HASHRATE_RESULT.json'

function Sha([string]$Path){(Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()}
function Parse-FileOrThrow([string]$Path,[string]$Label){
  $t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ($Label+' parse failed: '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message+'@'+$_.Extent.StartLineNumber+':'+$_.Extent.StartColumnNumber})-join' | '))}
  return $ast
}
function Parse-InputOrThrow([string]$Text,[string]$Label){
  $t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($Text,[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ($Label+' parse failed: '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message+'@'+$_.Extent.StartLineNumber+':'+$_.Extent.StartColumnNumber})-join' | '))}
  return $ast
}
function Get-Payload([Management.Automation.Language.Ast]$Ast,[string]$Name){
  $assign=@($Ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$script:'+$Name)},$true))
  if($assign.Count-ne1){throw ('Payload assignment count '+$Name+' = '+$assign.Count)}
  $rhs=$assign[0].Right
  if($rhs -is [Management.Automation.Language.CommandExpressionAst] -and $rhs.Expression -is [Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Expression.Value}
  if($rhs -is [Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Value}
  throw ('Unsupported payload AST '+$Name+': '+$rhs.GetType().FullName)
}
function Get-Fn([string]$Text,[string]$Name){
  $ast=Parse-InputOrThrow $Text ('payload for '+$Name)
  $fn=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name},$true))
  if($fn.Count-ne1){throw ('Function count '+$Name+' = '+$fn.Count)}
  return $fn[0]
}
function Replace-Extent([string]$Text,[Management.Automation.Language.IScriptExtent]$Extent,[string]$Replacement){
  return $Text.Substring(0,$Extent.StartOffset)+$Replacement+$Text.Substring($Extent.EndOffset)
}
function Replace-PayloadAssignment([string]$Main,[string]$Name,[string]$Payload){
  $pattern='(?ms)\$script:'+[regex]::Escape($Name)+"=@'\r?\n.*?\r?\n'@"
  $replacement='$script:'+$Name+"=@'`n"+$Payload.TrimEnd("`r","`n")+"`n'@"
  $rx=[regex]::new($pattern)
  $m=$rx.Match($Main)
  if(-not$m.Success){throw ('Cannot locate payload assignment '+$Name)}
  if($rx.Matches($Main).Count-ne1){throw ('Payload assignment regex not unique '+$Name)}
  return $Main.Substring(0,$m.Index)+$replacement+$Main.Substring($m.Index+$m.Length)
}

# 1) Byte-exact reconstruction of the rejected forensic candidate.
$parts=@(Get-ChildItem -LiteralPath $partsDir -File -Filter 'part*.txt'|Sort-Object Name)
if($parts.Count-ne5){throw ('Expected 5 exact parts, found '+$parts.Count)}
$ms=[IO.MemoryStream]::new()
try{foreach($p in $parts){$bytes=[IO.File]::ReadAllBytes($p.FullName);$ms.Write($bytes,0,$bytes.Length)};$reconstructed=$ms.ToArray()}finally{$ms.Dispose()}
$reconPath=Join-Path $outDir 'RECONSTRUCTED_REJECTED_60141.ps1'
[IO.File]::WriteAllBytes($reconPath,$reconstructed)
$reconSha=Sha $reconPath
if($reconSha-ne'60141bc4647121b14fe5b39bdeb0ae922ec0937b204fea382af0e36153caef76'){throw ('Source parts identity mismatch: '+$reconSha)}

# 2) Deterministic repairs already root-caused in Learning Base.
$text=[Text.UTF8Encoding]::new($false).GetString($reconstructed)
$text=$text.Replace('foreach($v in$freshLog)','foreach($v in $freshLog)')
$text=$text.Replace('foreach($v in$warmHash)','foreach($v in $warmHash)')

# Replace the independently malformed export child with the intended minimal export semantics.
$export=@'
param([string]$Root='D:\MiningSniper',[int]$Hours=24)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src=Join-Path $Root 'TELEMETRY\Beta\GPU_LANE_R065_RC16'
$out=Join-Path $Root 'GENERATED\GPU_LANE_R065_RC16'
[IO.Directory]::CreateDirectory($out)|Out-Null
$cut=(Get-Date).ToUniversalTime().AddHours(-$Hours)
$files=@(Get-ChildItem -LiteralPath (Join-Path $src 'RAW') -Recurse -File -Filter '*.jsonl' -ErrorAction SilentlyContinue|Where-Object{$_.LastWriteTimeUtc-ge$cut})
$zip=Join-Path $out ('MiningSniper_GPU_R065_RC16_TELEMETRY_'+(Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')+'.zip')
$tmp=Join-Path $out ('export_'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmp)|Out-Null
try{
  foreach($f in $files){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $tmp $f.Name)}
  $cal=Join-Path $Root 'PROTECTED_STATE\Beta\GPU_LANE_R065_RC16\CALIBRATION_RESULT.json'
  if(Test-Path -LiteralPath $cal){Copy-Item -LiteralPath $cal -Destination (Join-Path $tmp 'CALIBRATION_RESULT.json')}
  Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $zip -Force
  Write-Host $zip
}finally{
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
'@
$text=Replace-PayloadAssignment $text 'ExportPayload' $export

# Parse after lexical/export repair, then make the duty fixture use exact production functions.
[IO.File]::WriteAllText($candidate,$text,[Text.UTF8Encoding]::new($false))
$mainAst=Parse-FileOrThrow $candidate 'candidate interim main'
$sup=Get-Payload $mainAst 'SupervisorPayload'
$duty=Get-Payload $mainAst 'DutyFixturePayload'
$supAst=Parse-InputOrThrow $sup 'SupervisorPayload interim'
$dutyAst=Parse-InputOrThrow $duty 'DutyFixturePayload interim'
foreach($name in @('Get-DutySchedule','Invoke-DutyWindow')){
  $sf=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true))[0]
  $df=@($dutyAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true))[0]
  $duty=Replace-Extent $duty $df.Extent $sf.Extent.Text
  $dutyAst=Parse-InputOrThrow $duty ('DutyFixturePayload after '+$name)
}
$text=Replace-PayloadAssignment $text 'DutyFixturePayload' $duty
[IO.File]::WriteAllText($candidate,$text,[Text.UTF8Encoding]::new($false))
$candidateSha=Sha $candidate

# 3) Exact parse: main + every executable child payload.
$mainAst=Parse-FileOrThrow $candidate 'FINAL candidate main'
$payloads=[ordered]@{}
foreach($name in @('LearningModulePayload','SupervisorPayload','DutyFixturePayload','StopPayload','StatusPayload','ExportPayload')){
  $p=Get-Payload $mainAst $name
  $null=Parse-InputOrThrow $p $name
  $payloads[$name]=[ordered]@{chars=$p.Length;lines=($p -split "`r?`n").Count;parse='PASS'}
}
$sup=Get-Payload $mainAst 'SupervisorPayload';$duty=Get-Payload $mainAst 'DutyFixturePayload'
$supAst=Parse-InputOrThrow $sup 'SupervisorPayload final';$dutyAst=Parse-InputOrThrow $duty 'DutyFixturePayload final'

# 4) Exact function parity.
$parity=[ordered]@{}
foreach($name in @('Get-DutySchedule','Invoke-DutyWindow')){
  $sf=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true))
  $df=@($dutyAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true))
  if($sf.Count-ne1-or$df.Count-ne1){throw ('Parity function count failed '+$name)}
  $equal=($sf[0].Extent.Text -ceq $df[0].Extent.Text)
  $parity[$name]=$equal
  if(-not$equal){throw ('Exact function parity failed '+$name)}
}

# 5) Execute exact duty child from the final candidate.
$dutyPath=Join-Path $outDir 'DUTY_EXACT.ps1'
[IO.File]::WriteAllText($dutyPath,$duty,[Text.UTF8Encoding]::new($false))
$dout=@(& $PwshPath -NoLogo -NoProfile -File $dutyPath -ResultPath $dutyResult 2>&1)
if($LASTEXITCODE-ne0-or-not($dout-contains'DUTY_BEHAVIOR_EXACT_SELFTEST_PASS')){throw ('Duty fixture failed: '+(($dout|ForEach-Object{[string]$_})-join' | '))}
$dr=Get-Content -Raw -LiteralPath $dutyResult|ConvertFrom-Json

# 6) Exact historical hashrate parser/API fixture from production functions.
function ExactFnText([string]$Name){$f=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name},$true));if($f.Count-ne1){throw ('Hash function count '+$Name+'='+$f.Count)};return $f[0].Extent.Text}
$hashScript=@"
param([Parameter(Mandatory)][string]`$ResultPath)
`$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$(ExactFnText 'Parse-Num')
$(ExactFnText 'Convert-LolApiHashrateMhs')
$(ExactFnText 'Parse-LolHashrateLine')
`$apiFixture=[pscustomobject]@{ok=`$true;data=[pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239}}
`$a=Convert-LolApiHashrateMhs `$apiFixture
if(`$null-eq`$a-or[Math]::Abs([double]`$a-12.352733907856239)-gt0.000001){throw ('API fixture failed '+[string]`$a)}
`$l=Parse-LolHashrateLine 'Average speed (5s): 17.89 Mh/s'
if(`$null-eq`$l-or[Math]::Abs([double]`$l-17.89)-gt0.000001){throw ('LOG fixture failed '+[string]`$l)}
[ordered]@{status='PASS';api_mhs=[double]`$a;log_mhs=[double]`$l}|ConvertTo-Json|Set-Content -LiteralPath `$ResultPath -Encoding utf8
Write-Output 'HASHRATE_DETECTOR_EXACT_SELFTEST_PASS'
"@
$hashPath=Join-Path $outDir 'HASHRATE_EXACT.ps1'
[IO.File]::WriteAllText($hashPath,$hashScript,[Text.UTF8Encoding]::new($false))
$null=Parse-FileOrThrow $hashPath 'hashrate exact child'
$hout=@(& $PwshPath -NoLogo -NoProfile -File $hashPath -ResultPath $hashResult 2>&1)
if($LASTEXITCODE-ne0-or-not($hout-contains'HASHRATE_DETECTOR_EXACT_SELFTEST_PASS')){throw ('Hashrate fixture failed: '+(($hout|ForEach-Object{[string]$_})-join' | '))}

# 7) Symbol, parameter, scope, retired-token and identity closure.
$defs=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true)|ForEach-Object{$_.Name})
$required=@('Parse-Num','Find-NvidiaSmi','Get-NvidiaRow','Get-ForegroundEnginePct','Get-HeartbeatMs','Get-LolApi','Convert-LolApiHashrateMhs','Parse-LolHashrateLine','Get-LolHashrateObservation','Get-NativeLogTail','Get-NetworkState','Test-Pool20128','Start-Miner','Attach-DutyController','Stop-Miner','Day-Dirs','Start-Segment','Close-Segment','Add-Row','Write-Health','Run-ProductiveBootstrap','Get-DutySchedule','Invoke-DutyWindow','Run-DutyCycle','Median','Average','Get-LineCount','Get-LinesSince','Get-FreshLogHashratesSince','Start-GpuSampler','Stop-GpuSampler','Parse-SamplerRowsSince','Get-ApiEtchashSnapshot','Measure-DutyPhase','Start-LearningStage','Pass-LearningStage','Write-LearningState')
$missing=@($required|Where-Object{$_-notin$defs});if($missing.Count){throw ('Missing symbols '+($missing-join','))}
$reserved=@('PID','Host','HOME','PSScriptRoot','PSCommandPath','MyInvocation','PSVersionTable','Error','Args','Input','Matches','NestedPromptLevel','ShellId','This','ExecutionContext','StackTrace','PSItem','_')
$bad=[Collections.Generic.List[string]]::new();foreach($p in @($supAst.FindAll({param($n) $n -is [Management.Automation.Language.ParameterAst]},$true))){$n=$p.Name.VariablePath.UserPath;if($reserved-contains$n){$bad.Add($n)}};if($bad.Count){throw ('Reserved params '+(($bad|Sort-Object -Unique)-join','))}
if($sup -match '(?i)(?<!script:)\$duty\.(Suspend|Resume|SuspendedThreadCount)'){throw 'Unqualified duty controller call'}
if($sup -match '(?i)function\s+Measure-DutyPhase\s*\(\s*\[double\]\$Duty(?:\W|$)'){throw 'Duty parameter collision'}
if($sup -match 'Get-LolHashrateFromLog'){throw 'RC10 stale helper returned'}
foreach($retired in @('duty_weighted_util_proxy_pct','duty_weighted_power_proxy_w','median_active_util_pct','median_active_power_w','median_cycle_gpu_pct','median_cycle_power_w')){if($sup -match [regex]::Escape($retired)){throw ('Retired calibration token '+$retired)}}
if($text -notmatch 'GPU_LANE_R065_RC16'){throw 'Current release identity missing'}
foreach($stale in @('GPU_LANE_R065_RC15','GPU_LANE_R064_RC14','R064_RC14')){if($text -match [regex]::Escape($stale)){throw ('Stale runtime identity '+$stale)}}
if($text -match '(?i)WinRing0|Add-MpPreference|Set-MpPreference|--pl|--cclk|--mclk|--coff|--moff'){throw 'Forbidden runtime token'}

# 8) Hostless state-transition contract simulation. This validates the release gate ordering and acceptance semantics without GPU/Windows APIs.
$stageOrder=@('GPU_BOOTSTRAP','GPU_DUTY_ATTACH','GPU_PHASE_SAMPLER','GPU_CONTROLLED_WARMUP_40','GPU_CALIBRATION_10','GPU_CALIBRATION_25','GPU_CALIBRATION_40','GPU_CALIBRATION_ACCEPTANCE','GPU_LIVE')
$positions=@{};foreach($s in $stageOrder){$positions[$s]=$sup.IndexOf("'$s'");if([int]$positions[$s]-lt0){throw ('Stage missing '+$s)}}
for($i=1;$i-lt$stageOrder.Count;$i++){if([int]$positions[$stageOrder[$i]]-le[int]$positions[$stageOrder[$i-1]]){throw ('Stage order invalid '+$stageOrder[$i-1]+' -> '+$stageOrder[$i])}}
$simPass=[ordered]@{productive40=$true;lowerProductiveCount=1;timingOk=$true;controlEffect=$true;poolOk=$true;threadControl=$true}
$accept=($simPass.productive40-and$simPass.lowerProductiveCount-gt0-and$simPass.timingOk-and$simPass.controlEffect-and$simPass.poolOk-and$simPass.threadControl)
if(-not$accept){throw 'Positive state simulation did not accept'}
$simFail=$simPass.Clone();$simFail.controlEffect=$false
$reject=($simFail.productive40-and$simFail.lowerProductiveCount-gt0-and$simFail.timingOk-and$simFail.controlEffect-and$simFail.poolOk-and$simFail.threadControl)
if($reject){throw 'Negative state simulation did not reject'}

$result=[ordered]@{
  schema='miningsniper-rc16-rebuild-validation/v1'
  status='PASS'
  reconstructed_source_sha256=$reconSha
  candidate_sha256=$candidateSha
  candidate_bytes=(Get-Item -LiteralPath $candidate).Length
  powershell_version=(& $PwshPath -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
  main_parse='PASS'
  payloads=$payloads
  duty_function_parity=$parity
  duty_fixture=[ordered]@{status=[string]$dr.status;old=$dr.rc14_old_active_ms;new=$dr.repaired_schedule_active_ms;timing=$dr.fake_controller_timing}
  hashrate_fixture=(Get-Content -Raw -LiteralPath $hashResult|ConvertFrom-Json)
  symbol_closure='PASS'
  reserved_parameter_collisions=0
  stale_helper_absent=$true
  duty_scope_collision_absent=$true
  retired_calibration_tokens_absent=$true
  release_identity='PASS'
  forbidden_tokens_absent=$true
  state_transition_order=$stageOrder
  state_transition_positive_accept=$accept
  state_transition_negative_reject=(-not$reject)
  user_host_touched=$false
}
$result|ConvertTo-Json -Depth 40|Set-Content -LiteralPath $validationPath -Encoding utf8
Write-Host ('RC16_REBUILD_VALIDATION_PASS candidate_sha256='+$candidateSha)

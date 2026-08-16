param(
  [Parameter(Mandatory)][string]$Rc16Path,
  [Parameter(Mandatory)][string]$Rc17Path,
  [Parameter(Mandatory)][string]$Rc16ValidationPath,
  [Parameter(Mandatory)][string]$ResultPath
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

function Parse-Main([string]$Path){
  $t=$null;$e=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ('ParseFile failed '+$Path+': '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
  return $ast
}
function Get-Payload([object]$Ast,[string]$Name){
  $all=@($Ast.FindAll({param($n)
    if($n-isnot[Management.Automation.Language.AssignmentStatementAst]){return $false}
    return $n.Left.Extent.Text-eq('$script:'+$Name)
  },$true))
  if($all.Count-ne1){throw ('Payload assignment count '+$Name+'='+$all.Count)}
  $rhs=$all[0].Right
  if($rhs-isnot[Management.Automation.Language.CommandExpressionAst]){throw ('Unexpected RHS '+$Name+' '+$rhs.GetType().FullName)}
  $lit=$rhs.Expression
  if($lit-isnot[Management.Automation.Language.StringConstantExpressionAst]){throw ('Unexpected literal '+$Name+' '+$lit.GetType().FullName)}
  return [string]$lit.Value
}
function Get-FunctionText([object]$Ast,[string]$Name){
  $f=@($Ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq$Name},$true))
  if($f.Count-ne1){throw ('Function count '+$Name+'='+$f.Count)}
  return [string]$f[0].Extent.Text
}

$rc16Ast=Parse-Main $Rc16Path
$rc17Ast=Parse-Main $Rc17Path
$rc16Validation=Get-Content -Raw -LiteralPath $Rc16ValidationPath|ConvertFrom-Json
if([string]$rc16Validation.status-ne'PASS'){throw 'RC16 baseline validation is not PASS'}

$payloadNames=@('LearningModulePayload','SupervisorPayload','DutyFixturePayload','StopPayload','StatusPayload','ExportPayload')
$p16=@{};$p17=@{};$payloadParse=[ordered]@{}
foreach($n in $payloadNames){
  $p16[$n]=Get-Payload $rc16Ast $n
  $p17[$n]=Get-Payload $rc17Ast $n
  $t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseInput($p17[$n],[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ('RC17 payload ParseInput '+$n+': '+(($e|ForEach-Object{$_.Message})-join' | '))}
  $payloadParse[$n]='PASS'
}

# GPU/control behavior must be byte-text equivalent to the already fully validated RC16 payloads after identity normalization.
$gpuPayloadParity=[ordered]@{}
foreach($n in @('SupervisorPayload','DutyFixturePayload','StopPayload','StatusPayload','ExportPayload')){
  $norm=$p17[$n].Replace('GPU_LANE_R065_RC17','GPU_LANE_R065_RC16').Replace('R065_RC17','R065_RC16').Replace('GPU RC17','GPU RC16').Replace('RC17','RC16').Replace('0.65.2','0.65.1')
  $eq=($norm-ceq$p16[$n])
  $gpuPayloadParity[$n]=$eq
  if(-not$eq){throw ('GPU payload drift beyond release identity: '+$n)}
}

# Launcher itself must not call module-private helpers.
$commands=@($rc17Ast.FindAll({param($n)$n-is[Management.Automation.Language.CommandAst]},$true)|ForEach-Object{$_.GetCommandName()}|Where-Object{$_})
$privateHelpers=@('Get-MsLearningPaths','Get-MsNextRuntimeSeq','New-MsOrderedEvent','Write-MsJournalRecordDurable')
foreach($private in $privateHelpers){if($private-in$commands){throw ('Launcher directly calls private module helper '+$private)}}

$tmp=Join-Path $env:TEMP ('MS_RC17_VALIDATION_'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp|Out-Null
try{
  # Exact embedded module import/export closure and public selftest.
  $modulePath=Join-Path $tmp 'MiningSniper.Learning.psm1'
  Set-Content -LiteralPath $modulePath -Value $p17['LearningModulePayload'] -Encoding utf8
  $mt=$null;$me=$null;[void][Management.Automation.Language.Parser]::ParseFile($modulePath,[ref]$mt,[ref]$me)
  if($me.Count-gt0){throw ('Learning module parse failed: '+(($me|ForEach-Object{$_.Message})-join' | '))}
  Import-Module $modulePath -Force
  $mi=Get-Module|Where-Object{[string]$_.Path-eq[IO.Path]::GetFullPath($modulePath)}|Select-Object -First 1
  if($null-eq$mi){throw 'Module metadata missing'}
  $exports=@(Get-Command -Module $mi.Name|ForEach-Object{$_.Name})
  $requiredPublic=@('Sync-MiningSniperLearningBase','Write-MiningSniperLearningEvent','Start-MiningSniperLearningRun','Write-MiningSniperLearningStep','Invoke-MiningSniperLearningStep','Complete-MiningSniperLearningRun','Test-MiningSniperLearningStore')
  foreach($pub in $requiredPublic){if($pub-notin$exports){throw ('Missing exported public command '+$pub)}}
  foreach($priv in $privateHelpers){if($priv-in$exports){throw ('Private helper leaked as export '+$priv)}}

  $baseRoot=Join-Path $tmp 'base'
  New-Item -ItemType Directory -Force -Path $baseRoot|Out-Null
  $basePath=Join-Path $baseRoot 'MININGSNIPER_LEARNING_BASE.json'
  [ordered]@{schema='miningsniper-learning-base/v1';learning_revision=34;event_log=@([ordered]@{seq=65;overall='RC16_FAIL_INGESTED'});current_user_mandate=[ordered]@{};runtime_event_log=@();runtime_revision=0;runtime_learning=[ordered]@{}}|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $basePath -Encoding utf8
  $self=Test-MiningSniperLearningStore -ProjectRoot $baseRoot -SourceBasePath $basePath
  if([string]$self.status-ne'PASS'){throw 'Public learning store selftest did not PASS'}

  # Exact bootstrap persistence functions from the delivered launcher.
  $bootstrapFns=@('Get-BootstrapLearningSeq','Sync-BootstrapEventToCanonicalBase','Write-BootstrapLearningEvent')
  $texts=@();foreach($fn in $bootstrapFns){$texts+=Get-FunctionText $rc17Ast $fn}
  $bootRoot=Join-Path $tmp 'bootstrap'
  New-Item -ItemType Directory -Force -Path $bootRoot|Out-Null
  $bootBase=Join-Path $bootRoot 'MININGSNIPER_LEARNING_BASE.json'
  [ordered]@{schema='miningsniper-learning-base/v1';learning_revision=34;event_log=@();runtime_event_log=@();runtime_revision=0;runtime_learning=[ordered]@{}}|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $bootBase -Encoding utf8
  $bootScript=Join-Path $tmp 'BOOTSTRAP_PERSISTENCE_EXACT_SELFTEST.ps1'
  $bootResult=Join-Path $tmp 'BOOTSTRAP_PERSISTENCE_RESULT.json'
  $head=@'
param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$ResultPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$learningBasePath=Join-Path $Root 'MININGSNIPER_LEARNING_BASE.json'
$learningStateDir=Join-Path $Root 'PROTECTED_STATE\Learning'
$learningJournalPath=Join-Path $learningStateDir 'LEARNING_EVENTS.jsonl'
$learningRunId='deliberate_bootstrap_failure_run'
$Release='GPU_LANE_R065_RC17'
'@
  $tail=@'
Write-BootstrapLearningEvent 'RUN_START' 'RUN' 'STARTED' 'fixture' 'FIXTURE' 'start' @{}|Out-Null
Write-BootstrapLearningEvent 'STEP_START' 'LEARNING_BOOTSTRAP' 'START' 'fixture' 'STEP_ENTER' 'enter' @{}|Out-Null
Write-BootstrapLearningEvent 'STEP_FAIL' 'LEARNING_BOOTSTRAP' 'FAIL' 'fixture' 'DELIBERATE_FAIL' 'deliberate bootstrap failure' @{probe=17}|Out-Null
Write-BootstrapLearningEvent 'RUN_FINAL_FAIL' 'RUN' 'FAIL' 'fixture' 'DELIBERATE_FAIL' 'deliberate bootstrap failure' @{probe=17}|Out-Null
$b=Get-Content -Raw -LiteralPath $learningBasePath|ConvertFrom-Json
$mine=@($b.runtime_event_log|Where-Object{$_.run_id-eq$learningRunId})
if($mine.Count-ne4){throw ('Expected 4 immediate canonical bootstrap events, got '+$mine.Count)}
if(@($mine|Where-Object{$_.event_type-eq'STEP_FAIL'}).Count-ne1){throw 'STEP_FAIL missing from canonical base'}
if(@($mine|Where-Object{$_.event_type-eq'RUN_FINAL_FAIL'}).Count-ne1){throw 'RUN_FINAL_FAIL missing from canonical base'}
[ordered]@{status='PASS';event_count=$mine.Count;types=@($mine.event_type);runtime_revision=[long]$b.runtime_revision}|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $ResultPath -Encoding utf8
Write-Host 'BOOTSTRAP_FAILURE_BASE_PERSISTENCE_PASS'
'@
  Set-Content -LiteralPath $bootScript -Value ($head+"`n"+($texts-join"`n`n")+"`n"+$tail) -Encoding utf8
  $bt=$null;$be=$null;[void][Management.Automation.Language.Parser]::ParseFile($bootScript,[ref]$bt,[ref]$be)
  if($be.Count-gt0){throw ('Bootstrap exact child parse failed: '+(($be|ForEach-Object{$_.Message})-join' | '))}
  $bo=@(& pwsh -NoProfile -File $bootScript -Root $bootRoot -ResultPath $bootResult 2>&1)
  if($LASTEXITCODE-ne0-or($bo-notcontains'BOOTSTRAP_FAILURE_BASE_PERSISTENCE_PASS')){throw ('Bootstrap persistence fixture failed: '+($bo-join' | '))}
  $bootstrapProof=Get-Content -Raw -LiteralPath $bootResult|ConvertFrom-Json

  # Exact embedded duty fixture executes again in RC17.
  $dutyScript=Join-Path $tmp 'DUTY_RC17.ps1';$dutyResult=Join-Path $tmp 'DUTY_RC17.json'
  Set-Content -LiteralPath $dutyScript -Value $p17['DutyFixturePayload'] -Encoding utf8
  $do=@(& pwsh -NoProfile -File $dutyScript -ResultPath $dutyResult 2>&1)
  if($LASTEXITCODE-ne0-or($do-notcontains'DUTY_BEHAVIOR_EXACT_SELFTEST_PASS')){throw ('RC17 duty fixture failed: '+($do-join' | '))}
  $dutyProof=Get-Content -Raw -LiteralPath $dutyResult|ConvertFrom-Json

  # Exact production hashrate functions from RC17 supervisor.
  $st=$null;$se=$null;$supAst=[Management.Automation.Language.Parser]::ParseInput($p17['SupervisorPayload'],[ref]$st,[ref]$se)
  if($se.Count-gt0){throw 'Supervisor payload parse unexpectedly failed'}
  $hashScript=Join-Path $tmp 'HASH_RC17.ps1'
  $hashText=(Get-FunctionText $supAst 'Parse-LolHashrateLine')+"`n`n"+(Get-FunctionText $supAst 'Convert-LolApiHashrateMhs')+@'

$api=[pscustomobject]@{ok=$true;data=[pscustomobject]@{Algorithms=@([pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239})}}
$a=Convert-LolApiHashrateMhs $api
$l=Parse-LolHashrateLine 'Average speed (5s): 17.89 Mh/s'
if([Math]::Abs([double]$a-12.352733907856239)-gt0.000001){throw 'API fixture failed'}
if([Math]::Abs([double]$l-17.89)-gt0.000001){throw 'Log fixture failed'}
Write-Host 'HASHRATE_RC17_PASS'
'@
  Set-Content -LiteralPath $hashScript -Value $hashText -Encoding utf8
  $ho=@(& pwsh -NoProfile -File $hashScript 2>&1)
  if($LASTEXITCODE-ne0-or($ho-notcontains'HASHRATE_RC17_PASS')){throw ('RC17 hashrate fixture failed: '+($ho-join' | '))}

  $result=[ordered]@{
    schema='miningsniper-rc17-prechat-validation/v1'
    status='PASS'
    powershell=$PSVersionTable.PSVersion.ToString()
    rc16_baseline_validation='PASS'
    rc17_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $Rc17Path).Hash.ToLowerInvariant()
    rc17_bytes=(Get-Item -LiteralPath $Rc17Path).Length
    main_parse='PASS'
    payload_parse=$payloadParse
    gpu_payload_identity_normalized_parity=$gpuPayloadParity
    launcher_private_module_calls=0
    module_export_boundary='PASS'
    public_learning_store_selftest='PASS'
    bootstrap_failure_base_persistence=$bootstrapProof
    exact_duty_fixture_status=[string]$dutyProof.status
    exact_duty_old=$dutyProof.rc14_old_active_ms
    exact_duty_new=$dutyProof.repaired_schedule_active_ms
    hashrate_api_mhs=12.352733907856239
    hashrate_log_mhs=17.89
    rc17_identity_present=((Get-Content -Raw -LiteralPath $Rc17Path)-match'GPU_LANE_R065_RC17')
    rc16_identity_absent=(-not((Get-Content -Raw -LiteralPath $Rc17Path)-match'RC16'))
    user_host_touched=$false
  }
  if(-not$result.rc17_identity_present-or-not$result.rc16_identity_absent){throw 'Release identity closure failed'}
  $result|ConvertTo-Json -Depth 30|Set-Content -LiteralPath $ResultPath -Encoding utf8
  Write-Host 'MININGSNIPER_RC17_PRECHAT_PASS'
}finally{
  Remove-Module -Name MiningSniper.Learning -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

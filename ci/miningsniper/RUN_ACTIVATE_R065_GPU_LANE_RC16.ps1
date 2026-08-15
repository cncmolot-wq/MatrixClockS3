param([string]$Root='D:\MiningSniper')
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$script:LearningModulePayload=@'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:MiningSniperLearningWriterVersion = '1.2'
$script:MiningSniperLearningMutexName = 'Local\MiningSniperLearningBaseV1'

function Get-MsLearningPaths {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    [pscustomobject]@{
        Root       = $root
        Base       = Join-Path $root 'MININGSNIPER_LEARNING_BASE.json'
        BaseTemp   = Join-Path $root 'MININGSNIPER_LEARNING_BASE.json.tmp'
        BaseBackup = Join-Path $root 'MININGSNIPER_LEARNING_BASE.json.bak'
        Learning   = Join-Path $root 'PROTECTED_STATE\Learning'
        Journal    = Join-Path $root 'PROTECTED_STATE\Learning\LEARNING_EVENTS.jsonl'
    }
}

function New-MsOrderedEvent {
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][long]$RuntimeSeq,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][string]$EventType,
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Outcome,
        [string]$Decision,
        [string]$ReasonCode,
        [string]$ReasonText,
        [hashtable]$ComponentOutcomes,
        [hashtable]$Evidence,
        [string]$RootCauseStatus = 'OBSERVED_ONLY',
        [string]$RootCauseOrUnknown = 'UNKNOWN_FROM_RUNTIME',
        [string]$Source = 'SCRIPT'
    )
    [ordered]@{
        event_id              = [guid]::NewGuid().ToString('N')
        run_id                = $RunId
        runtime_seq           = $RuntimeSeq
        utc                   = [DateTimeOffset]::UtcNow.ToString('o')
        writer_version        = $script:MiningSniperLearningWriterVersion
        source                = $Source
        release               = $Release
        event_type            = $EventType
        stage                 = $Stage
        outcome               = $Outcome
        decision              = $Decision
        reason_code           = $ReasonCode
        reason_text           = $ReasonText
        component_outcomes    = if($null -ne $ComponentOutcomes){$ComponentOutcomes}else{@{}}
        evidence              = if($null -ne $Evidence){$Evidence}else{@{}}
        root_cause_status     = $RootCauseStatus
        root_cause_or_unknown = $RootCauseOrUnknown
    }
}

function Read-MsLearningBase {
    param([Parameter(Mandatory)][string]$BasePath)
    if(-not (Test-Path -LiteralPath $BasePath -PathType Leaf)){
        throw "Learning base missing: $BasePath"
    }
    $raw = Get-Content -Raw -LiteralPath $BasePath -Encoding UTF8
    if([string]::IsNullOrWhiteSpace($raw)){ throw "Learning base is empty: $BasePath" }
    return ($raw | ConvertFrom-Json -AsHashtable -Depth 100)
}

function Read-MsJournalRecords {
    param([Parameter(Mandatory)][string]$JournalPath)
    $records = [Collections.Generic.List[object]]::new()
    if(-not (Test-Path -LiteralPath $JournalPath -PathType Leaf)){ return @() }
    foreach($line in [IO.File]::ReadLines($JournalPath)){
        if([string]::IsNullOrWhiteSpace($line)){ continue }
        try{
            $obj = $line | ConvertFrom-Json -AsHashtable -Depth 100
            if($obj.ContainsKey('event_id') -and $obj.ContainsKey('runtime_seq')){
                $records.Add($obj)
            }
        }catch{
            # A torn/corrupt tail is preserved in the journal for later forensic review.
            # Valid prior lines continue to replay.
        }
    }
    return @($records)
}

function Test-MsJournalNeedsSeparator {
    param([Parameter(Mandatory)][string]$JournalPath)
    if(-not(Test-Path -LiteralPath $JournalPath -PathType Leaf)){ return $false }
    $fs=[IO.FileStream]::new($JournalPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try{
        if($fs.Length-le0){ return $false }
        [void]$fs.Seek(-1,[IO.SeekOrigin]::End)
        $last=$fs.ReadByte()
        return ($last-ne10 -and $last-ne13)
    }finally{
        $fs.Dispose()
    }
}

function Write-MsJournalRecordDurable {
    param(
        [Parameter(Mandatory)][string]$JournalPath,
        [Parameter(Mandatory)][hashtable]$Record
    )
    $dir = Split-Path -Parent $JournalPath
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    $prefix = if(Test-MsJournalNeedsSeparator -JournalPath $JournalPath){[Environment]::NewLine}else{''}
    $json = $prefix + ($Record | ConvertTo-Json -Compress -Depth 100) + [Environment]::NewLine
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)

    $fs = [IO.FileStream]::new(
        $JournalPath,
        [IO.FileMode]::Append,
        [IO.FileAccess]::Write,
        [IO.FileShare]::Read,
        4096,
        [IO.FileOptions]::WriteThrough
    )
    try{
        $fs.Write($bytes,0,$bytes.Length)
        $fs.Flush($true)
    } finally {
        $fs.Dispose()
    }
}

function Write-MsBaseAtomic {
    param(
        [Parameter(Mandatory)][hashtable]$Base,
        [Parameter(Mandatory)][pscustomobject]$Paths
    )
    $json = $Base | ConvertTo-Json -Depth 100
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json + [Environment]::NewLine)

    if(Test-Path -LiteralPath $Paths.BaseTemp){ Remove-Item -LiteralPath $Paths.BaseTemp -Force }
    $fs = [IO.FileStream]::new(
        $Paths.BaseTemp,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None,
        65536,
        [IO.FileOptions]::WriteThrough
    )
    try{
        $fs.Write($bytes,0,$bytes.Length)
        $fs.Flush($true)
    } finally {
        $fs.Dispose()
    }

    if(Test-Path -LiteralPath $Paths.Base){
        try{
            [IO.File]::Replace($Paths.BaseTemp,$Paths.Base,$Paths.BaseBackup,$true)
        }catch{
            Copy-Item -LiteralPath $Paths.Base -Destination $Paths.BaseBackup -Force
            [IO.File]::Move($Paths.BaseTemp,$Paths.Base,$true)
        }
    }else{
        [IO.File]::Move($Paths.BaseTemp,$Paths.Base)
    }
}

function Sync-MiningSniperLearningBase {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $paths = Get-MsLearningPaths -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($paths.Learning) | Out-Null
    $base = Read-MsLearningBase -BasePath $paths.Base

    if(-not $base.ContainsKey('runtime_event_log')){ $base['runtime_event_log'] = @() }
    if(-not $base.ContainsKey('runtime_revision')){ $base['runtime_revision'] = 0 }
    if(-not $base.ContainsKey('runtime_learning')){ $base['runtime_learning'] = [ordered]@{} }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($e in @($base['runtime_event_log'])){
        if($null -ne $e -and $e.ContainsKey('event_id')){ [void]$seen.Add([string]$e['event_id']) }
    }

    $records = @(Read-MsJournalRecords -JournalPath $paths.Journal | Sort-Object {[long]$_['runtime_seq']})
    $added = 0
    $maxSeq = [long]$base['runtime_revision']
    foreach($r in $records){
        $id = [string]$r['event_id']
        $seq = [long]$r['runtime_seq']
        if($seq -gt $maxSeq){ $maxSeq = $seq }
        if($seen.Add($id)){
            $base['runtime_event_log'] += ,$r
            $added++
        }
    }

    $base['runtime_revision'] = $maxSeq
    $last = $null
    if(@($base['runtime_event_log']).Count -gt 0){ $last = @($base['runtime_event_log'])[-1] }

    $base['runtime_learning']['writer_version'] = $script:MiningSniperLearningWriterVersion
    $base['runtime_learning']['runtime_event_count'] = @($base['runtime_event_log']).Count
    $base['runtime_learning']['last_event'] = $last
    $base['runtime_learning']['last_synced_utc'] = [DateTimeOffset]::UtcNow.ToString('o')
    $base['runtime_learning']['journal'] = 'PROTECTED_STATE\Learning\LEARNING_EVENTS.jsonl'
    $base['runtime_learning']['journal_replay_status'] = 'PASS'

    Write-MsBaseAtomic -Base $base -Paths $paths
    [pscustomobject]@{ added=$added; runtime_revision=$maxSeq; event_count=@($base['runtime_event_log']).Count }
}

function Get-MsNextRuntimeSeq {
    param([Parameter(Mandatory)][string]$JournalPath)
    $max = 0L
    foreach($r in @(Read-MsJournalRecords -JournalPath $JournalPath)){
        $s = [long]$r['runtime_seq']
        if($s -gt $max){ $max = $s }
    }
    return ($max + 1L)
}

function Write-MiningSniperLearningEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][string]$EventType,
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Outcome,
        [string]$Decision,
        [string]$ReasonCode,
        [string]$ReasonText,
        [hashtable]$ComponentOutcomes,
        [hashtable]$Evidence,
        [string]$RootCauseStatus = 'OBSERVED_ONLY',
        [string]$RootCauseOrUnknown = 'UNKNOWN_FROM_RUNTIME',
        [string]$Source = 'SCRIPT'
    )

    $mutex = [Threading.Mutex]::new($false,$script:MiningSniperLearningMutexName)
    $locked = $false
    try{
        try{
            $locked = $mutex.WaitOne([TimeSpan]::FromSeconds(30))
        }catch [Threading.AbandonedMutexException]{
            # Abandoned means the previous owner died while holding it; this caller now owns the mutex.
            $locked = $true
        }
        if(-not $locked){ throw 'Learning store mutex timeout' }

        $paths = Get-MsLearningPaths -ProjectRoot $ProjectRoot
        if(-not (Test-Path -LiteralPath $paths.Base)){ throw "Learning base missing: $($paths.Base)" }
        $seq = Get-MsNextRuntimeSeq -JournalPath $paths.Journal
        $event = New-MsOrderedEvent -RunId $RunId -RuntimeSeq $seq -Release $Release -EventType $EventType `
            -Stage $Stage -Outcome $Outcome -Decision $Decision -ReasonCode $ReasonCode -ReasonText $ReasonText `
            -ComponentOutcomes $ComponentOutcomes -Evidence $Evidence -RootCauseStatus $RootCauseStatus `
            -RootCauseOrUnknown $RootCauseOrUnknown -Source $Source

        # WRITE-AHEAD: this is the primary durability point.
        Write-MsJournalRecordDurable -JournalPath $paths.Journal -Record $event

        # Best-effort compile into canonical base. If this throws, event is already durable in the journal.
        Sync-MiningSniperLearningBase -ProjectRoot $ProjectRoot | Out-Null
        return [pscustomobject]$event
    } finally {
        if($locked){ $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Start-MiningSniperLearningRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][string]$EntryPoint,
        [Parameter(Mandatory)][string]$Intent,
        [Parameter(Mandatory)][string]$Decision
    )
    $runId = ([guid]::NewGuid().ToString('N'))
    Write-MiningSniperLearningEvent -ProjectRoot $ProjectRoot -RunId $runId -Release $Release `
        -EventType 'RUN_START' -Stage 'RUN' -Outcome 'STARTED' -Decision $Decision `
        -ReasonCode 'RUN_REQUESTED' -ReasonText $Intent -Evidence @{
            entry_point=$EntryPoint
            process_id=$PID
            host=[Environment]::MachineName
            pwsh=$PSVersionTable.PSVersion.ToString()
        } | Out-Null
    return $runId
}

function Write-MiningSniperLearningStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][string]$StepId,
        [Parameter(Mandatory)][ValidateSet('START','PASS','FAIL','UNKNOWN')][string]$Outcome,
        [Parameter(Mandatory)][string]$Decision,
        [Parameter(Mandatory)][string]$ReasonCode,
        [Parameter(Mandatory)][string]$ReasonText,
        [hashtable]$Evidence,
        [hashtable]$ComponentOutcomes
    )
    $eventType = if($Outcome -eq 'START'){'STEP_START'}elseif($Outcome -eq 'PASS'){'STEP_PASS'}elseif($Outcome -eq 'FAIL'){'STEP_FAIL'}else{'COMPONENT_EVIDENCE'}
    Write-MiningSniperLearningEvent -ProjectRoot $ProjectRoot -RunId $RunId -Release $Release `
        -EventType $eventType -Stage $StepId -Outcome $Outcome -Decision $Decision `
        -ReasonCode $ReasonCode -ReasonText $ReasonText -Evidence $Evidence `
        -ComponentOutcomes $ComponentOutcomes
}

function Invoke-MiningSniperLearningStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][string]$StepId,
        [Parameter(Mandatory)][string]$Decision,
        [Parameter(Mandatory)][scriptblock]$Action,
        [string]$PassReasonCode = 'STEP_COMPLETED',
        [string]$PassReasonText = 'Decision-critical step completed without exception.',
        [scriptblock]$EvidenceScript
    )
    Write-MiningSniperLearningStep -ProjectRoot $ProjectRoot -RunId $RunId -Release $Release `
        -StepId $StepId -Outcome START -Decision $Decision -ReasonCode 'STEP_ENTER' `
        -ReasonText 'Entering decision-critical step.' | Out-Null
    try{
        $result = & $Action
        $evidence = @{}
        if($null -ne $EvidenceScript){
            $tmp = & $EvidenceScript $result
            if($tmp -is [hashtable]){ $evidence = $tmp }
        }
        Write-MiningSniperLearningStep -ProjectRoot $ProjectRoot -RunId $RunId -Release $Release `
            -StepId $StepId -Outcome PASS -Decision $Decision -ReasonCode $PassReasonCode `
            -ReasonText $PassReasonText -Evidence $evidence | Out-Null
        return $result
    }catch{
        $ex = $_
        $evidence = @{
            exception_type = $ex.Exception.GetType().FullName
            exception_message = $ex.Exception.Message
            script_stack = $ex.ScriptStackTrace
            position_message = $ex.InvocationInfo.PositionMessage
        }
        Write-MiningSniperLearningStep -ProjectRoot $ProjectRoot -RunId $RunId -Release $Release `
            -StepId $StepId -Outcome FAIL -Decision $Decision -ReasonCode 'EXCEPTION' `
            -ReasonText $ex.Exception.Message -Evidence $evidence | Out-Null
        throw
    }
}

function Complete-MiningSniperLearningRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Release,
        [Parameter(Mandatory)][ValidateSet('PASS','FAIL')][string]$Outcome,
        [Parameter(Mandatory)][string]$ReasonCode,
        [Parameter(Mandatory)][string]$ReasonText,
        [hashtable]$Evidence,
        [hashtable]$ComponentOutcomes
    )
    $eventType = if($Outcome -eq 'PASS'){'RUN_FINAL_PASS'}else{'RUN_FINAL_FAIL'}
    Write-MiningSniperLearningEvent -ProjectRoot $ProjectRoot -RunId $RunId -Release $Release `
        -EventType $eventType -Stage 'RUN' -Outcome $Outcome -Decision 'Finalize runtime attempt' `
        -ReasonCode $ReasonCode -ReasonText $ReasonText -Evidence $Evidence `
        -ComponentOutcomes $ComponentOutcomes
}

Export-ModuleMember -Function @(
    'Sync-MiningSniperLearningBase',
    'Write-MiningSniperLearningEvent',
    'Start-MiningSniperLearningRun',
    'Write-MiningSniperLearningStep',
    'Invoke-MiningSniperLearningStep',
    'Complete-MiningSniperLearningRun'
)
'@

$script:DutyFixturePayload=@'
param([Parameter(Mandatory)][string]$ResultPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

class FakeDutyController {
  [int]$ResumeCount=0
  [int]$SuspendCount=0
  [int] Resume(){ $this.ResumeCount++; return 1 }
  [int] Suspend(){ $this.SuspendCount++; return 1 }
}

function Get-DutySchedule([double]$DutyFraction,[int]$CycleLengthMs){
  if($CycleLengthMs-le0){throw 'Duty cycle length must be > 0 ms'}
  $clamped=[double]$DutyFraction
  if([double]::IsNaN($clamped)-or[double]::IsInfinity($clamped)){throw 'Duty fraction must be finite'}
  if($clamped-lt0.0){$clamped=0.0}
  elseif($clamped-gt1.0){$clamped=1.0}
  $activeMs=[int][Math]::Round(($clamped*[double]$CycleLengthMs),0,[MidpointRounding]::AwayFromZero)
  if($activeMs-lt0){$activeMs=0}
  elseif($activeMs-gt$CycleLengthMs){$activeMs=$CycleLengthMs}
  return [pscustomobject][ordered]@{
    requested_duty=[double]$DutyFraction
    clamped_duty=$clamped
    cycle_ms=$CycleLengthMs
    active_ms=$activeMs
  }
}

function Invoke-DutyWindow([object]$Controller,[double]$DutyFraction,[int]$CycleLengthMs){
  $schedule=Get-DutySchedule $DutyFraction $CycleLengthMs
  $awakeElapsed=0.0
  $resumeResult=0
  $suspendResult=0
  if([int]$schedule.active_ms-gt0){
    $resumeResult=[int]$Controller.Resume()
    $awakeSw=[Diagnostics.Stopwatch]::StartNew()
    Start-Sleep -Milliseconds ([int]$schedule.active_ms)
    $awakeSw.Stop()
    $awakeElapsed=$awakeSw.Elapsed.TotalMilliseconds
    $suspendResult=[int]$Controller.Suspend()
  }
  $actualDuty=if($CycleLengthMs-gt0){$awakeElapsed/[double]$CycleLengthMs}else{0.0}
  if($actualDuty-lt0.0){$actualDuty=0.0}
  elseif($actualDuty-gt1.0){$actualDuty=1.0}
  return [pscustomobject][ordered]@{
    schedule=$schedule
    resume_result=$resumeResult
    suspend_result=$suspendResult
    actual_awake_ms=$awakeElapsed
    actual_duty_fraction=$actualDuty
  }
}

function Get-Rc14OldActiveMs([double]$Target,[int]$CycleLengthMs){
  return [int][Math]::Round([Math]::Max(0,[Math]::Min(1,$Target))*$CycleLengthMs)
}

$old=[ordered]@{
  d10=(Get-Rc14OldActiveMs 0.10 2000)
  d25=(Get-Rc14OldActiveMs 0.25 2000)
  d40=(Get-Rc14OldActiveMs 0.40 2000)
}

if($old.d10-ne0-or$old.d25-ne0-or$old.d40-ne0){
  throw ('RC14 overload fixture did not reproduce zero duty: '+($old|ConvertTo-Json -Compress))
}

$expected=@{'0.1'=200;'0.25'=500;'0.4'=800}
$schedules=@{}
$timing=@{}

# Warm the exact timing path once. The first Start-Sleep invocation in a cold hosted PowerShell
# process can include one-time runtime/JIT overhead unrelated to the duty scheduler itself.
$warmFake=[FakeDutyController]::new()
$null=Invoke-DutyWindow $warmFake 0.10 1000

foreach($d in @(0.10,0.25,0.40)){
  $key=[string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0:0.##}',$d)
  $s=Get-DutySchedule ([double]$d) 2000
  if([int]$s.active_ms-ne[int]$expected[$key]){
    throw ('New schedule wrong for '+$key+': '+[int]$s.active_ms)
  }
  $schedules[$key]=[int]$s.active_ms

  $samples=@()
  foreach($rep in 1..3){
    $fake=[FakeDutyController]::new()
    $w=Invoke-DutyWindow $fake ([double]$d) 1000
    if($fake.ResumeCount-ne1-or$fake.SuspendCount-ne1){
      throw ('Fake controller call count wrong for '+$key+' rep='+$rep)
    }
    if([double]$w.actual_awake_ms-le0){
      throw ('Actual awake time was zero for '+$key+' rep='+$rep)
    }
    $samples += [double]$w.actual_duty_fraction
  }

  $sorted=@($samples|Sort-Object)
  $median=[double]$sorted[1]
  $err=[Math]::Abs($median-[double]$d)
  if($err-gt0.10){
    throw ('Median actual duty timing outside tolerance for '+$key+': '+$median+' samples='+($samples -join ','))
  }

  $timing[$key]=[ordered]@{
    actual_duty_median=$median
    actual_duty_samples=@($samples)
    resume_count_each=1
    suspend_count_each=1
  }
}

$result=[ordered]@{
  status='PASS'
  rc14_old_active_ms=$old
  repaired_schedule_active_ms=$schedules
  fake_controller_timing=$timing
  timing_method='one discarded warmup + median of 3 exact duty windows per target'
  root_cause_status='PROVEN_BY_EXECUTABLE_FIXTURE'
  root_cause='Mixed numeric overload in RC14 quantized fractional Target through Int32 Math.Min; explicit double clamp removes overload ambiguity.'
}
$result|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $ResultPath -Encoding utf8
Write-Output 'DUTY_BEHAVIOR_EXACT_SELFTEST_PASS'
'@

$script:SupervisorPayload=@'
param(
  [Parameter(Mandatory)][string]$Root,
  [Parameter(Mandatory)][string]$StateDir,
  [Parameter(Mandatory)][string]$TelemetryRoot,
  [Parameter(Mandatory)][string]$GeneratedDir,
  [Parameter(Mandatory)][string]$LolMinerExe,
  [Parameter(Mandatory)][string]$LolMinerLog,
  [Parameter(Mandatory)][string]$NvidiaSmi,
  [Parameter(Mandatory)][int]$ApiPort,
  [Parameter(Mandatory)][string]$PoolHost,
  [Parameter(Mandatory)][int]$PoolPort,
  [Parameter(Mandatory)][string]$LearningModulePath,
  [Parameter(Mandatory)][string]$LearningRunId
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$Release='GPU_LANE_R065_RC16';$Version='0.65.1-gpu-rc16';$sessionId=([guid]::NewGuid().ToString('N'))
$state=$StateDir;$telemetry=$TelemetryRoot;$generated=$GeneratedDir;$pidFile=Join-Path $state 'supervisor.pid';$minerPidFile=Join-Path $state 'miner.pid';$health=Join-Path $state 'RUNTIME_HEALTH.json';$stopMarker=Join-Path $state 'STOP_REQUESTED_GPU_R065';$calibrationFile=Join-Path $state 'CALIBRATION_RESULT.json';$learningModule=$LearningModulePath;$learningRun=$LearningRunId
foreach($d in @($state,$telemetry,$generated)){[IO.Directory]::CreateDirectory($d)|Out-Null};$PID|Set-Content -LiteralPath $pidFile -Encoding ascii
Import-Module $learningModule -Force
$script:learningStages=@{}
function Start-LearningStage([string]$Stage,[string]$Decision,[hashtable]$Evidence=@{}){
  Write-MiningSniperLearningStep -ProjectRoot $Root -RunId $learningRun -Release $Release -StepId $Stage -Outcome START -Decision $Decision -ReasonCode 'STEP_ENTER' -ReasonText 'Entering GPU decision-critical stage.' -Evidence $Evidence|Out-Null
  $script:learningStages[$Stage]=$Decision
}
function Pass-LearningStage([string]$Stage,[string]$ReasonCode,[string]$ReasonText,[hashtable]$Evidence=@{},[hashtable]$ComponentOutcomes=@{}){
  $decision=if($script:learningStages.ContainsKey($Stage)){$script:learningStages[$Stage]}else{$Stage}
  Write-MiningSniperLearningStep -ProjectRoot $Root -RunId $learningRun -Release $Release -StepId $Stage -Outcome PASS -Decision $decision -ReasonCode $ReasonCode -ReasonText $ReasonText -Evidence $Evidence -ComponentOutcomes $ComponentOutcomes|Out-Null
}
function Write-LearningState([string]$Stage,[string]$Outcome,[string]$ReasonCode,[string]$ReasonText,[hashtable]$Evidence=@{},[hashtable]$ComponentOutcomes=@{}){
  Write-MiningSniperLearningEvent -ProjectRoot $Root -RunId $learningRun -Release $Release -EventType 'STATE_TRANSITION' -Stage $Stage -Outcome $Outcome -Decision $Stage -ReasonCode $ReasonCode -ReasonText $ReasonText -Evidence $Evidence -ComponentOutcomes $ComponentOutcomes|Out-Null
}
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
public sealed class GpuThreadDutyController {
 [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr OpenThread(uint access, bool inherit, uint tid);
 [DllImport("kernel32.dll", SetLastError=true)] static extern uint SuspendThread(IntPtr hThread);
 [DllImport("kernel32.dll", SetLastError=true)] static extern uint ResumeThread(IntPtr hThread);
 [DllImport("kernel32.dll", SetLastError=true)] static extern bool CloseHandle(IntPtr hObject);
 const uint THREAD_SUSPEND_RESUME=0x0002;
 readonly int pid;
 readonly Dictionary<int,int> held=new Dictionary<int,int>();
 public GpuThreadDutyController(int processId){ pid=processId; }
 int Apply(bool suspend){
  Process p=Process.GetProcessById(pid); int changed=0;
  foreach(ProcessThread t in p.Threads){ int tid=t.Id; IntPtr h=OpenThread(THREAD_SUSPEND_RESUME,false,(uint)tid); if(h==IntPtr.Zero)continue;
   try{
    if(suspend){ uint r=SuspendThread(h); if(r!=0xffffffff){ int n;held.TryGetValue(tid,out n);held[tid]=n+1;changed++; } }
    else { int n;if(held.TryGetValue(tid,out n)&&n>0){ uint r=ResumeThread(h);if(r!=0xffffffff){n--;changed++;if(n==0)held.Remove(tid);else held[tid]=n;} } }
   } finally { CloseHandle(h); }
  } return changed;
 }
 public int Suspend(){return Apply(true);} public int Resume(){return Apply(false);} public int SuspendedThreadCount{get{int n=0;foreach(var kv in held)n+=kv.Value;return n;}}
 public void ResumeAll(){ for(int round=0;round<32 && held.Count>0;round++) Apply(false); }
}
"@
function Parse-Num([object]$v){if($null-eq$v){return$null};$s=([string]$v).Trim();if($s-eq''-or$s-eq'N/A'-or$s-eq'[N/A]'){return$null};$n=0.0;if([double]::TryParse($s,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$n)){return$n};return$null}
function Find-NvidiaSmi(){if(-not[string]::IsNullOrWhiteSpace($NvidiaSmi)-and(Test-Path -LiteralPath $NvidiaSmi)){return$NvidiaSmi};$cmd=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue;if($cmd){return$cmd.Source};foreach($p in @("$env:ProgramW6432\NVIDIA Corporation\NVSMI\nvidia-smi.exe","$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe")){if(Test-Path -LiteralPath $p){return$p}};return$null}
$script:smi=Find-NvidiaSmi;if($null-eq$smi){throw 'nvidia-smi.exe not found after activator preflight'}
function Get-NvidiaRow(){try{$out=& $smi '--query-gpu=index,name,utilization.gpu,memory.total,memory.used,temperature.gpu,power.draw,pstate' '--format=csv,noheader,nounits' 2>&1;$rc=$LASTEXITCODE;if($rc-ne0){return[pscustomobject]@{ok=$false;error=('exit='+$rc+' '+(($out|ForEach-Object{[string]$_})-join' | '))}};$line=@($out|Where-Object{$_-is[string]-and$_ -match '^\s*\d+\s*,'})|Select-Object -First 1;if($null-eq$line){return[pscustomobject]@{ok=$false;error='no parseable NVIDIA row';stdout=(($out|ForEach-Object{[string]$_})-join' | ')}};$p=[string]$line -split','|ForEach-Object{$_.Trim()};return[pscustomobject]@{ok=$true;index=[int]$p[0];name=$p[1];util_pct=(Parse-Num $p[2]);memory_total_mb=(Parse-Num $p[3]);memory_used_mb=(Parse-Num $p[4]);temp_c=(Parse-Num $p[5]);power_w=(Parse-Num $p[6]);pstate=$p[7];error=$null;backend=$smi}}catch{return[pscustomobject]@{ok=$false;error=$_.Exception.Message;backend=$smi}}}
function Get-ForegroundEnginePct([int]$MinerProcessId){try{$c=Get-Counter '\GPU Engine(*)\Utilization Percentage' -ErrorAction Stop;$sum=0.0;foreach($s in$c.CounterSamples){$path=[string]$s.Path;if($path-match'pid_(\d+)'){if([int]$matches[1]-ne$MinerProcessId){$sum+=[double]$s.CookedValue}}};return[Math]::Min(100.0,$sum)}catch{return$null}}
function Get-HeartbeatMs(){try{$sw=[Diagnostics.Stopwatch]::StartNew();[void](Get-Process -Id $PID -ErrorAction Stop);$sw.Stop();return$sw.Elapsed.TotalMilliseconds}catch{return9999.0}}
function Get-LolApi(){try{$r=Invoke-RestMethod -Uri ("http://127.0.0.1:$ApiPort/summary") -TimeoutSec 2;return[pscustomobject]@{ok=$true;data=$r;error=$null}}catch{return[pscustomobject]@{ok=$false;data=$null;error=$_.Exception.Message}}}
function Convert-LolApiHashrateMhs([object]$ApiObj){
  if($null-eq$ApiObj){return$null};$ok=$false;try{$ok=[bool]$ApiObj.ok}catch{};if(-not$ok){return$null}
  $data=$null;try{$data=$ApiObj.data}catch{};if($null-eq$data){return$null}
  $unit='';try{$unit=[string]$data.Performance_Unit}catch{};if($unit-ne'Mh/s'){return$null}
  $v=$null;try{$v=Parse-Num $data.Total_Performance}catch{};if($null-ne$v-and[double]$v-gt0){return[double]$v};return$null
}
function Parse-LolHashrateLine([string]$Line){
  if([string]::IsNullOrWhiteSpace($Line)){return$null}
  $m=[regex]::Match($Line,'(?i)Average\s+speed(?:\s*\([^)]*\))?\s*:\s*([0-9]+(?:[\.,][0-9]+)?)\s*Mh/s')
  if(-not$m.Success){return$null};$v=0.0;if([double]::TryParse(($m.Groups[1].Value-replace',','.'),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)-and$v-gt0){return$v};return$null
}
function Get-LolHashrateObservation([object]$ApiObj){
  $apiHash=Convert-LolApiHashrateMhs $ApiObj
  if($null-ne$apiHash-and[double]$apiHash-gt0){return[pscustomobject]@{mhs=[double]$apiHash;source='API_TOTAL_PERFORMANCE';raw=[double]$apiHash;fresh=$true}}
  if(Test-Path -LiteralPath $LolMinerLog){
    try{$lines=Get-Content -LiteralPath $LolMinerLog -Tail 120 -ErrorAction Stop;for($i=$lines.Count-1;$i-ge0;$i--){$v=Parse-LolHashrateLine ([string]$lines[$i]);if($null-ne$v-and[double]$v-gt0){return[pscustomobject]@{mhs=[double]$v;source='NATIVE_LOG_AVERAGE_SPEED';raw=[string]$lines[$i];fresh=$false}}}}catch{}
  }
  return[pscustomobject]@{mhs=$null;source='NONE';raw=$null;fresh=$false}
}
function Get-NativeLogTail([int]$Lines=80){if(-not(Test-Path -LiteralPath $LolMinerLog)){return@()};try{return@(Get-Content -LiteralPath $LolMinerLog -Tail $Lines -ErrorAction Stop)}catch{return@('LOG_READ_ERROR: '+$_.Exception.Message)}}
function Get-NetworkState([int]$ProcessId){try{$c=@(Get-NetTCPConnection -OwningProcess $ProcessId -ErrorAction Stop|Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State);$pool=@($c|Where-Object{$_.RemotePort-eq$PoolPort});$est=@($pool|Where-Object{$_.State-eq'Established'});return[pscustomobject]@{ok=$true;pool_20128=($est.Count-gt0);pool_20128_any_state=($pool.Count-gt0);connections=@($c);error=$null}}catch{return[pscustomobject]@{ok=$false;pool_20128=$false;pool_20128_any_state=$false;connections=@();error=$_.Exception.Message}}}
function Test-Pool20128([object]$Net){if($null-eq$Net){return$false};try{return[bool]$Net.pool_20128}catch{return$false}}
function Start-Miner{
  $args=@('--algo','ETCHASH','--pool',($PoolHost+':'+$PoolPort),'--user','miningsniper','--tls','on','--ethstratum','ETHV1','--mode','b','--apiport',[string]$ApiPort,'--log','on','--logfile',$LolMinerLog,'--shortstats','5','--longstats','60','--timeprint','on')
  $p=Start-Process -FilePath $LolMinerExe -ArgumentList $args -PassThru -WindowStyle Hidden
  $p.Id|Set-Content -LiteralPath $minerPidFile -Encoding ascii;return$p
}
function Attach-DutyController([Diagnostics.Process]$Process){return[GpuThreadDutyController]::new($Process.Id)}
function Stop-Miner([Diagnostics.Process]$Process){if($null-ne$script:dutyController){try{$script:dutyController.ResumeAll()}catch{}};if($null-ne$Process-and-not$Process.HasExited){try{Stop-Process -Id $Process.Id -Force -ErrorAction Stop}catch{}}}
function Day-Dirs([DateTime]$Utc){$y=$Utc.ToString('yyyy');$m=$Utc.ToString('MM');$d=$Utc.ToString('dd');$raw=Join-Path $telemetry (Join-Path 'RAW' (Join-Path $y (Join-Path $m $d)));$rep=Join-Path $telemetry (Join-Path 'REPORTS' (Join-Path $y (Join-Path $m $d)));[IO.Directory]::CreateDirectory($raw)|Out-Null;[IO.Directory]::CreateDirectory($rep)|Out-Null;return@($raw,$rep)}
$script:segment=$null;$script:segmentHour=$null;$script:segmentStart=$null;$script:segmentLast=$null;$script:segmentRows=0
function Start-Segment([DateTime]$Utc){$dirs=Day-Dirs $Utc;$stamp=$Utc.ToString('yyyyMMddTHH');$path=Join-Path $dirs[0] ('gpu_segment_'+$stamp+'Z_'+$PID+'.open.jsonl');$script:segment=$path;$script:segmentHour=$Utc.ToString('yyyyMMddHH');$script:segmentStart=$Utc;$script:segmentLast=$Utc;$script:segmentRows=0;Set-Content -LiteralPath $path -Value '' -Encoding utf8}
function Close-Segment([DateTime]$Utc,[string]$Reason='UTC_HOUR_ROLLOVER'){if($null-eq$segment){return};$dirs=Day-Dirs $Utc;$start=$segmentStart;if($null-eq$start){$s=$start.ToString('yyyyMMddTHHmmss')+'Z'}else{$s='unknown'};$e=$segmentLast.ToString('yyyyMMddTHHmmss')+'Z';$final=Join-Path $dirs[0] ('gpu_segment_'+$s+'_'+$e+'_'+$PID+'.jsonl');Move-Item -LiteralPath $segment -Destination $final -Force;$report=[ordered]@{schema_version='1.0';release=$Release;reason=$Reason;start_utc=if($null-ne$start){$start.ToString('o')}else{$null};end_utc=$segmentLast.ToString('o');duration_s=if($null-ne$start){[Math]::Round(($segmentLast-$start).TotalSeconds,3)}else{0};samples=$segmentRows;raw_file=$final};$report|ConvertTo-Json -Depth 20|Set-Content -LiteralPath (Join-Path $dirs[1] ('gpu_report_'+$s+'_'+$e+'_'+$PID+'.json')) -Encoding utf8;$script:segment=$null}
function Add-Row([hashtable]$Row){$u=(Get-Date).ToUniversalTime();if($null-eq$segment){Start-Segment $u};if($segmentHour-ne$u.ToString('yyyyMMddHH')){Close-Segment $u;Start-Segment $u};Add-Content -LiteralPath $segment -Value ($Row|ConvertTo-Json -Compress -Depth 25) -Encoding utf8;$script:segmentLast=$u;$script:segmentRows++}
function Write-Health([string]$Mode,[double]$Duty,[object]$Gpu,[object]$Foreground,[object]$Net,[bool]$Paused,[object]$Hashrate,[string]$HashrateSource){$h=[ordered]@{utc=(Get-Date).ToUniversalTime().ToString('o');release=$Release;version=$Version;mode=$Mode;supervisor_pid=$PID;miner_pid=if($null-ne$miner){$miner.Id}else{$null};normalized_duty_target=$Duty;live_floor=$script:liveFloor;loop_samples=$script:loopSamples;api_port=$ApiPort;pool=($PoolHost+':'+$PoolPort);gpu=$Gpu;foreground_gpu_pct=$Foreground;network=$Net;paused=$Paused;suspended_threads=if($null-ne$script:dutyController){$script:dutyController.SuspendedThreadCount}else{0};telemetry_failures=$script:telemetryFailures;last_nonzero_duty=$script:lastNonzeroDuty;recovery_stable_cycles=$script:recoveryStable;hashrate_mhs=$Hashrate;hashrate_source=$HashrateSource};$tmp=$health+'.tmp';$h|ConvertTo-Json -Depth 25|Set-Content -LiteralPath $tmp -Encoding utf8;Move-Item -LiteralPath $tmp -Destination $health -Force}
function Run-ProductiveBootstrap([Diagnostics.Process]$Process){
  $started=(Get-Date).ToUniversalTime();$deadline=$started.AddSeconds(75);$everHash=$false;$everPoolEstablished=$false;$everPoolAny=$false;$everApi=$false;$maxGpuUtil=0.0;$maxPower=0.0;$maxMem=0.0;$maxTemp=0.0;$sampleIndex=0;$tail=[Collections.Generic.List[object]]::new()
  while((Get-Date).ToUniversalTime()-lt$deadline){
    if($Process.HasExited){throw ('lolMiner exited during bootstrap code='+$Process.ExitCode+' logTail='+(Get-NativeLogTail 80-join' | '))}
    $g=Get-NvidiaRow;$fg=Get-ForegroundEnginePct $Process.Id;$heartbeat=Get-HeartbeatMs;$net=Get-NetworkState $Process.Id;$api=if(($sampleIndex%4)-eq0){Get-LolApi}else{$null};$hashObs=Get-LolHashrateObservation $api;$hash=$hashObs.mhs
    if($g.ok){if($null-ne$g.util_pct){$maxGpuUtil=[Math]::Max($maxGpuUtil,[double]$g.util_pct)};if($null-ne$g.power_w){$maxPower=[Math]::Max($maxPower,[double]$g.power_w)};if($null-ne$g.memory_used_mb){$maxMem=[Math]::Max($maxMem,[double]$g.memory_used_mb)};if($null-ne$g.temp_c){$maxTemp=[Math]::Max($maxTemp,[double]$g.temp_c)}}
    $freeMb=if($g.ok-and$null-ne$g.memory_total_mb-and$null-ne$g.memory_used_mb){[double]$g.memory_total_mb-[double]$g.memory_used_mb}else{$null}
    if($g.ok){if($null-ne$g.temp_c-and[double]$g.temp_c-ge75){throw 'GPU thermal safety stop during bootstrap >=75C'};if($null-ne$freeMb-and[double]$freeMb-lt512){throw 'GPU VRAM free headroom below 512 MB during bootstrap'}};if($heartbeat-ge1500){throw 'Host responsiveness safety stop during bootstrap: heartbeat >=1500 ms'}
    $hashReady=($null-ne$hash -and [double]$hash-gt0);$poolReady=(Test-Pool20128 $net);$poolAny=$false;try{$poolAny=[bool]$net.pool_20128_any_state}catch{};$apiReady=($null-ne$api -and $api.ok)
    if($hashReady){$everHash=$true};if($poolReady){$everPoolEstablished=$true};if($poolAny){$everPoolAny=$true};if($apiReady){$everApi=$true}
    $row=[ordered]@{utc=(Get-Date).ToUniversalTime().ToString('o');release=$Release;session_id=$sessionId;mode='BOOTSTRAP_CONTINUOUS_UNTHROTTLED_INITIALIZATION';normalized_duty_target=$null;gpu=$g;foreground_gpu=$fg;vram_free_mb=$freeMb;heartbeat_ms=[Math]::Round($heartbeat,3);network=$net;api=$api;hashrate_mhs=$hash;hashrate_source=$hashObs.source;hashrate_raw=$hashObs.raw;hash_ready=$hashReady;pool_ready=$poolReady;pool_any_state=$poolAny;miner_alive=(-not$Process.HasExited);suspended_threads=0}
    Add-Row $row;$script:loopSamples++;Write-Health 'BOOTSTRAP_CONTINUOUS_UNTHROTTLED_INITIALIZATION' 1.0 $g $fg $net $false $hashObs.mhs $hashObs.source;$tail.Add([pscustomobject]$row);while($tail.Count-gt12){$tail.RemoveAt(0)}
    if($hashReady-and$poolReady){
      $result=[ordered]@{schema_version='1.0';release=$Release;status='PASS_PRODUCTIVE_BOOTSTRAP';started_utc=$started.ToString('o');completed_utc=(Get-Date).ToUniversalTime().ToString('o');wall_seconds=[Math]::Round(((Get-Date).ToUniversalTime()-$started).TotalSeconds,3);ever_hash_positive=$everHash;ever_pool_established=$everPoolEstablished;ever_pool_any_state=$everPoolAny;ever_api_ready=$everApi;last_hashrate_mhs=$hash;last_hashrate_source=$hashObs.source;last_hashrate_raw=$hashObs.raw;max_gpu_util_pct=$maxGpuUtil;max_power_w=$maxPower;max_memory_used_mb=$maxMem;max_temp_c=$maxTemp;native_log_tail=(Get-NativeLogTail 60);recent_samples=@($tail)}
      $result|ConvertTo-Json -Depth 30|Set-Content -LiteralPath (Join-Path $state 'BOOTSTRAP_RESULT.json') -Encoding utf8;return [pscustomobject]$result
    }
    $sampleIndex++;Start-Sleep -Milliseconds 750
  }
  $fail=[ordered]@{schema_version='1.0';release=$Release;status='FAIL_BOOTSTRAP_NOT_PRODUCTIVE';started_utc=$started.ToString('o');completed_utc=(Get-Date).ToUniversalTime().ToString('o');wall_seconds=[Math]::Round(((Get-Date).ToUniversalTime()-$started).TotalSeconds,3);ever_hash_positive=$everHash;ever_pool_established=$everPoolEstablished;ever_pool_any_state=$everPoolAny;ever_api_ready=$everApi;max_gpu_util_pct=$maxGpuUtil;max_power_w=$maxPower;max_memory_used_mb=$maxMem;max_temp_c=$maxTemp;native_log_tail=(Get-NativeLogTail 100);recent_samples=@($tail)}
  $fail|ConvertTo-Json -Depth 30|Set-Content -LiteralPath (Join-Path $state 'BOOTSTRAP_RESULT.json') -Encoding utf8
  throw ('GPU bootstrap failed: hash='+$everHash+' poolEstablished='+$everPoolEstablished+' poolAnyState='+$everPoolAny+' api='+$everApi+' maxPowerW='+[Math]::Round($maxPower,1)+' maxMemMB='+[Math]::Round($maxMem,0))
}
function Get-DutySchedule([double]$DutyFraction,[int]$CycleLengthMs){
  if($CycleLengthMs-le0){throw 'Duty cycle length must be > 0 ms'}
  $clamped=[double]$DutyFraction
  if([double]::IsNaN($clamped)-or[double]::IsInfinity($clamped)){throw 'Duty fraction must be finite'}
  if($clamped-lt0.0){$clamped=0.0}
  elseif($clamped-gt1.0){$clamped=1.0}
  $activeMs=[int][Math]::Round(($clamped*[double]$CycleLengthMs),0,[MidpointRounding]::AwayFromZero)
  if($activeMs-lt0){$activeMs=0}
  elseif($activeMs-gt$CycleLengthMs){$activeMs=$CycleLengthMs}
  return [pscustomobject][ordered]@{
    requested_duty=[double]$DutyFraction
    clamped_duty=$clamped
    cycle_ms=$CycleLengthMs
    active_ms=$activeMs
  }
}
function Invoke-DutyWindow([object]$Controller,[double]$DutyFraction,[int]$CycleLengthMs){
  $schedule=Get-DutySchedule $DutyFraction $CycleLengthMs
  $awakeElapsed=0.0
  $resumeResult=0
  $suspendResult=0
  if([int]$schedule.active_ms-gt0){
    $resumeResult=[int]$Controller.Resume()
    $awakeSw=[Diagnostics.Stopwatch]::StartNew()
    Start-Sleep -Milliseconds ([int]$schedule.active_ms)
    $awakeSw.Stop()
    $awakeElapsed=$awakeSw.Elapsed.TotalMilliseconds
    $suspendResult=[int]$Controller.Suspend()
  }
  $actualDuty=if($CycleLengthMs-gt0){$awakeElapsed/[double]$CycleLengthMs}else{0.0}
  if($actualDuty-lt0.0){$actualDuty=0.0}
  elseif($actualDuty-gt1.0){$actualDuty=1.0}
  return [pscustomobject][ordered]@{
    schedule=$schedule
    resume_result=$resumeResult
    suspend_result=$suspendResult
    actual_awake_ms=$awakeElapsed
    actual_duty_fraction=$actualDuty
  }
}
function Run-DutyCycle([double]$Target,[string]$Mode,[int]$CycleLengthMs=1000,[bool]$ProbeActive=$false){
  $cycleSw=[Diagnostics.Stopwatch]::StartNew()
  $null=$script:dutyController.Suspend()
  Start-Sleep -Milliseconds 180

  $offGpu=Get-NvidiaRow
  $fg=Get-ForegroundEnginePct $miner.Id
  $heartbeat=Get-HeartbeatMs
  $freeMb=if($offGpu.ok){[double]$offGpu.memory_total_mb-[double]$offGpu.memory_used_mb}else{$null}

  if($offGpu.ok){$script:telemetryFailures=0}else{$script:telemetryFailures++}
  if($telemetryFailures-ge3){throw 'GPU telemetry backend failed 3 consecutive cycles; refusing blind mining'}
  if($offGpu.ok){
    if($null-ne$offGpu.temp_c -and [double]$offGpu.temp_c-ge75){throw 'GPU thermal safety stop >=75C'}
    if($null-ne$freeMb -and [double]$freeMb-lt512){throw 'GPU VRAM free headroom below 512 MB'}
  }
  if([double]$heartbeat-ge1500){throw 'Host responsiveness safety stop: heartbeat >=1500 ms'}

  $window=Invoke-DutyWindow $script:dutyController $Target $CycleLengthMs
  $awakeElapsed=[double]$window.actual_awake_ms
  $actualDuty=[double]$window.actual_duty_fraction

  $elapsed=[int]$cycleSw.ElapsedMilliseconds
  $rest=$CycleLengthMs-$elapsed
  if($rest-gt0){Start-Sleep -Milliseconds $rest}
  $cycleSw.Stop()

  $net=Get-NetworkState $miner.Id
  $api=if(($loopSamples%10)-eq0){Get-LolApi}else{$null}
  $hashObs=Get-LolHashrateObservation $api

  $row=[ordered]@{
    utc=(Get-Date).ToUniversalTime().ToString('o')
    release=$Release
    session_id=$sessionId
    mode=$Mode
    normalized_duty_target=[double]$Target
    scheduled_active_ms=[int]$window.schedule.active_ms
    scheduled_cycle_ms=[int]$window.schedule.cycle_ms
    actual_awake_ms=[Math]::Round($awakeElapsed,3)
    actual_duty_fraction=[Math]::Round($actualDuty,6)
    off_gpu=$offGpu
    foreground_gpu=$fg
    vram_free_mb=$freeMb
    heartbeat_ms=[Math]::Round($heartbeat,3)
    network=$net
    api=$api
    hashrate_mhs=$hashObs.mhs
    hashrate_source=$hashObs.source
    hashrate_raw=$hashObs.raw
    miner_alive=(-not$miner.HasExited)
    suspended_threads=$script:dutyController.SuspendedThreadCount
    controller_resume_result=[int]$window.resume_result
    controller_suspend_result=[int]$window.suspend_result
  }
  Add-Row $row;$script:loopSamples++;Write-Health $Mode $Target $offGpu $fg $net $false $hashObs.mhs $hashObs.source
  return[pscustomobject]$row
}
function Median([double[]]$Values){$a=@($Values|Sort-Object);if($a.Count-eq0){return$null};if(($a.Count%2)-eq1){return[double]$a[[int][Math]::Floor($a.Count/2)]};$i=$a.Count/2;return([double]$a[$i-1]+[double]$a[$i])/2.0}
function Average([double[]]$Values){if($null-eq$Values-or$Values.Count-eq0){return$null};return[double](($Values|Measure-Object -Average).Average)}
function Get-LineCount([string]$Path){if(-not(Test-Path -LiteralPath $Path)){return0};try{return@(Get-Content -LiteralPath $Path).Count}catch{return0}}
function Get-LinesSince([string]$Path,[int]$StartIndex){if(-not(Test-Path -LiteralPath $Path)){return@()};$all=@(Get-Content -LiteralPath $Path -ErrorAction Stop);if($StartIndex-lt0){$StartIndex=0};if($StartIndex-ge$all.Count){return@()};return@($all[$StartIndex..($all.Count-1)])}
function Get-FreshLogHashratesSince([string]$Path,[int]$StartIndex){$vals=[Collections.Generic.List[double]]::new();foreach($line in@(Get-LinesSince $Path $StartIndex)){ $v=Parse-LolHashrateLine ([string]$line);if($null-ne$v-and[double]$v-gt0){$vals.Add([double]$v)}};return@($vals)}
function Start-GpuSampler([string]$CsvPath){if(Test-Path -LiteralPath $CsvPath){Remove-Item -LiteralPath $CsvPath -Force};$args=@('--query-gpu=timestamp,utilization.gpu,power.draw,temperature.gpu,memory.used,pstate','--format=csv,noheader,nounits','--loop-ms=200','--filename',$CsvPath);return Start-Process -FilePath $smi -ArgumentList $args -PassThru -WindowStyle Hidden}
function Stop-GpuSampler([Diagnostics.Process]$Sampler){if($null-ne$Sampler-and-not$Sampler.HasExited){try{Stop-Process -Id $Sampler.Id -Force -ErrorAction Stop}catch{}}}
function Parse-SamplerRowsSince([string]$CsvPath,[int]$StartIndex){
  $rows=[Collections.Generic.List[object]]::new();if(-not(Test-Path -LiteralPath $CsvPath)){return@()};$all=@(Get-Content -LiteralPath $CsvPath -ErrorAction Stop);if($StartIndex-lt0){$StartIndex=0};if($StartIndex-ge$all.Count){return@()}
  foreach($line in@($all[$StartIndex..($all.Count-1)])){$p=[string]$line-split','|ForEach-Object{$_.Trim()};if($p.Count-lt6){continue};$u=Parse-Num $p[1];$pw=Parse-Num $p[2];$t=Parse-Num $p[3];$m=Parse-Num $p[4];if($null-eq$u-and$null-eq$pw){continue};$rows.Add([pscustomobject]@{timestamp=$p[0];util_pct=$u;power_w=$pw;temp_c=$t;memory_used_mb=$m;pstate=$p[5]})};return@($rows)
}
function Get-ApiEtchashSnapshot(){
  $a=Get-LolApi;if($null-eq$a-or-not$a.ok){return$null};$h=Convert-LolApiHashrateMhs $a;if($null-eq$h-or[double]$h-le0){return$null};return[pscustomobject]@{mhs=[double]$h;source='API_TOTAL_PERFORMANCE';raw=$a.data}
}
function Measure-DutyPhase([double]$DutyFraction,[int]$SettleSeconds=8,[int]$MeasureSeconds=20){
  for($i=0;$i-lt$SettleSeconds;$i++){[void](Run-DutyCycle $DutyFraction ('CALIBRATION_'+[int]($DutyFraction*100)+'_SETTLE') 1000 $false)}
  $samplerStart=Get-LineCount $script:samplerCsv;$logStart=Get-LineCount $LolMinerLog
  $cycles=[Collections.Generic.List[object]]::new();$end=(Get-Date).AddSeconds($MeasureSeconds)
  while((Get-Date)-lt$end){$cycles.Add((Run-DutyCycle $DutyFraction ('CALIBRATION_'+[int]($DutyFraction*100)+'_MEASURE') 1000 $false))}
  Start-Sleep -Milliseconds 350
  $sampleRows=@(Parse-SamplerRowsSince $script:samplerCsv $samplerStart)
  $freshLogHash=@(Get-FreshLogHashratesSince $LolMinerLog $logStart)
  $apiSnap=Get-ApiEtchashSnapshot
  $hashVals=[Collections.Generic.List[double]]::new();foreach($v in$freshLogHash){$hashVals.Add([double]$v)};if($null-ne$apiSnap){$hashVals.Add([double]$apiSnap.mhs)}
  $util=@($sampleRows|Where-Object{$null-ne$_.util_pct}|ForEach-Object{[double]$_.util_pct});$power=@($sampleRows|Where-Object{$null-ne$_.power_w}|ForEach-Object{[double]$_.power_w});$temps=@($sampleRows|Where-Object{$null-ne$_.temp_c}|ForEach-Object{[double]$_.temp_c});$duties=@($cycles|ForEach-Object{[double]$_.actual_duty_fraction});$awake=@($cycles|ForEach-Object{[double]$_.actual_awake_ms});$poolFraction=if($cycles.Count-gt0){(@($cycles|Where-Object{Test-Pool20128 $_.network}).Count/[double]$cycles.Count)}else{0}
  return[pscustomobject][ordered]@{
    target_duty=[double]$DutyFraction;cycle_count=$cycles.Count;sampler_samples=$sampleRows.Count;actual_duty_mean=(Average $duties);actual_duty_median=(Median $duties);actual_awake_ms_mean=(Average $awake);sampler_util_mean_pct=(Average $util);sampler_util_median_pct=(Median $util);sampler_power_mean_w=(Average $power);sampler_power_median_w=(Median $power);sampler_temp_max_c=if($temps.Count-gt0){($temps|Measure-Object -Maximum).Maximum}else{$null};fresh_log_hash_samples=$freshLogHash.Count;fresh_log_hash_median_mhs=(Median $freshLogHash);api_hashrate_mhs=if($null-ne$apiSnap){[double]$apiSnap.mhs}else{$null};fresh_hashrate_mhs=if($hashVals.Count-gt0){(Median @($hashVals))}else{$null};pool_fraction=[Math]::Round($poolFraction,4);min_suspended_threads=if($cycles.Count-gt0){($cycles|Measure-Object suspended_threads -Minimum).Minimum}else{$null};max_suspended_threads=if($cycles.Count-gt0){($cycles|Measure-Object suspended_threads -Maximum).Maximum}else{$null}
  }
}
$script:dutyController=$null;$script:liveFloor=0.25;$script:loopSamples=0;$script:telemetryFailures=0;$script:lastNonzeroDuty=0.40;$script:recoveryStable=0;$script:sampler=$null;$script:samplerCsv=Join-Path $state 'NVIDIA_PHASE_SAMPLER.csv';$miner=$null
try{
  Start-LearningStage 'GPU_BOOTSTRAP' 'Bring already-proven lolMiner/Etchash path to the productive state required for duty-control testing' @{basic_gpu_mining_already_proven=$true;bootstrap_cap_s=75}
  $miner=Start-Miner;Start-Sleep -Milliseconds 120;$boot=Run-ProductiveBootstrap $miner
  Pass-LearningStage 'GPU_BOOTSTRAP' 'PASS_PRODUCTIVE_BOOTSTRAP' 'lolMiner reached pool-connected productive Etchash state; this is a prerequisite, not the release decision.' @{hashrate_mhs=[double]$boot.last_hashrate_mhs;hashrate_source=[string]$boot.last_hashrate_source;pool_established=[bool]$boot.ever_pool_established;wall_seconds=[double]$boot.wall_seconds;max_power_w=[double]$boot.max_power_w;max_temp_c=[double]$boot.max_temp_c}

  Start-LearningStage 'GPU_DUTY_ATTACH' 'Attach explicit script-scoped duty controller only after productive bootstrap'
  $script:dutyController=Attach-DutyController $miner;$attach=$script:dutyController.Suspend();Start-Sleep -Milliseconds 250;if($script:dutyController.SuspendedThreadCount-le0){throw 'GPU duty controller attach did not produce suspended threads'}
  Pass-LearningStage 'GPU_DUTY_ATTACH' 'DUTY_CONTROLLER_ATTACHED' 'Duty controller attached after bootstrap and suspended miner threads.' @{suspended_threads=[int]$script:dutyController.SuspendedThreadCount;attach_result=[int]$attach}

  Start-LearningStage 'GPU_PHASE_SAMPLER' 'Start independent NVIDIA telemetry sampler outside duty active windows'
  $script:sampler=Start-GpuSampler $script:samplerCsv;Start-Sleep -Milliseconds 700;if($script:sampler.HasExited){throw 'Independent NVIDIA sampler exited immediately'}
  Pass-LearningStage 'GPU_PHASE_SAMPLER' 'INDEPENDENT_SAMPLER_ACTIVE' 'Independent nvidia-smi sampler remains alive.' @{sampler_pid=$script:sampler.Id;sampler_csv=$script:samplerCsv}

  Start-LearningStage 'GPU_CONTROLLED_WARMUP_40' 'Prove the repaired scheduler creates a real productive 40 percent controlled phase'
  $warmLog=Get-LineCount $LolMinerLog;$warmSampler=Get-LineCount $script:samplerCsv;$warmCycles=[Collections.Generic.List[object]]::new();$warmEnd=(Get-Date).AddSeconds(20);while((Get-Date)-lt$warmEnd){$warmCycles.Add((Run-DutyCycle 0.40 'CONTROLLED_WARMUP_40' 1000 $false))};Start-Sleep -Milliseconds 350
  $warmSamples=@(Parse-SamplerRowsSince $script:samplerCsv $warmSampler);$warmHash=@(Get-FreshLogHashratesSince $LolMinerLog $warmLog);$warmApi=Get-ApiEtchashSnapshot;$warmHashVals=[Collections.Generic.List[double]]::new();foreach($v in$warmHash){$warmHashVals.Add([double]$v)};if($null-ne$warmApi){$warmHashVals.Add([double]$warmApi.mhs)};$warmDuties=@($warmCycles|ForEach-Object{[double]$_.actual_duty_fraction});$warmDuty=Average $warmDuties;$warmPool=if($warmCycles.Count-gt0){(@($warmCycles|Where-Object{Test-Pool20128 $_.network}).Count/[double]$warmCycles.Count)}else{0};$warmResult=[ordered]@{schema_version='2.0';release=$Release;status='CONTROLLED_40_WARMUP_EVIDENCE';cycles=$warmCycles.Count;sampler_samples=$warmSamples.Count;actual_duty_mean=$warmDuty;pool_fraction=$warmPool;fresh_log_hash_samples=$warmHash.Count;api_hashrate_mhs=if($null-ne$warmApi){[double]$warmApi.mhs}else{$null};fresh_hashrate_mhs=if($warmHashVals.Count-gt0){(Median @($warmHashVals))}else{$null};sampler_util_mean_pct=(Average @($warmSamples|Where-Object{$null-ne$_.util_pct}|ForEach-Object{[double]$_.util_pct}));sampler_power_mean_w=(Average @($warmSamples|Where-Object{$null-ne$_.power_w}|ForEach-Object{[double]$_.power_w}));min_suspended_threads=if($warmCycles.Count-gt0){($warmCycles|Measure-Object suspended_threads -Minimum).Minimum}else{$null}}
  $warmResult|ConvertTo-Json -Depth 25|Set-Content -LiteralPath (Join-Path $state 'WARMUP_RESULT.json') -Encoding utf8
  if($warmSamples.Count-lt20-or$null-eq$warmDuty-or[double]$warmDuty-lt0.25-or[double]$warmDuty-gt0.55-or$warmPool-lt0.80-or$warmHashVals.Count-lt1){throw ('Controlled 40 warmup evidence failed: sampler='+$warmSamples.Count+' poolFraction='+$warmPool+' freshHashCount='+$warmHashVals.Count+' actualDuty='+$warmDuty)}
  Pass-LearningStage 'GPU_CONTROLLED_WARMUP_40' 'PASS_CONTROLLED_40_WARMUP' 'Repaired scheduler kept controlled 40 percent phase productive with independent evidence.' @{actual_duty_mean=[double]$warmDuty;pool_fraction=[double]$warmPool;fresh_hashrate_mhs=[double]$warmResult.fresh_hashrate_mhs;sampler_samples=[int]$warmSamples.Count;min_suspended_threads=[int]$warmResult.min_suspended_threads}

  Start-LearningStage 'GPU_CALIBRATION_10' 'Measure fresh phase-local 10 percent duty behavior'
  $p10=Measure-DutyPhase 0.10;Pass-LearningStage 'GPU_CALIBRATION_10' 'PHASE_MEASURED' '10 percent phase completed with independent telemetry.' @{actual_duty_mean=$p10.actual_duty_mean;fresh_hashrate_mhs=$p10.fresh_hashrate_mhs;pool_fraction=$p10.pool_fraction;sampler_power_mean_w=$p10.sampler_power_mean_w;sampler_util_mean_pct=$p10.sampler_util_mean_pct}
  Start-LearningStage 'GPU_CALIBRATION_25' 'Measure fresh phase-local 25 percent duty behavior'
  $p25=Measure-DutyPhase 0.25;Pass-LearningStage 'GPU_CALIBRATION_25' 'PHASE_MEASURED' '25 percent phase completed with independent telemetry.' @{actual_duty_mean=$p25.actual_duty_mean;fresh_hashrate_mhs=$p25.fresh_hashrate_mhs;pool_fraction=$p25.pool_fraction;sampler_power_mean_w=$p25.sampler_power_mean_w;sampler_util_mean_pct=$p25.sampler_util_mean_pct}
  Start-LearningStage 'GPU_CALIBRATION_40' 'Measure fresh phase-local 40 percent duty behavior'
  $p40=Measure-DutyPhase 0.40;Pass-LearningStage 'GPU_CALIBRATION_40' 'PHASE_MEASURED' '40 percent phase completed with independent telemetry.' @{actual_duty_mean=$p40.actual_duty_mean;fresh_hashrate_mhs=$p40.fresh_hashrate_mhs;pool_fraction=$p40.pool_fraction;sampler_power_mean_w=$p40.sampler_power_mean_w;sampler_util_mean_pct=$p40.sampler_util_mean_pct}

  Start-LearningStage 'GPU_CALIBRATION_ACCEPTANCE' 'Decide whether corrected duty scheduling creates a productive measurable 10/25/40 control surface'
  $phases=@($p10,$p25,$p40);$productive=@($phases|Where-Object{$null-ne$_.fresh_hashrate_mhs-and[double]$_.fresh_hashrate_mhs-gt0-and[double]$_.pool_fraction-ge0.80});$productive40=($null-ne$p40.fresh_hashrate_mhs-and[double]$p40.fresh_hashrate_mhs-gt0-and[double]$p40.pool_fraction-ge0.80);$lowerProductive=@($productive|Where-Object{[double]$_.target_duty-lt0.40})
  $timingOk=$true;foreach($p in$phases){if($null-eq$p.actual_duty_mean-or[Math]::Abs([double]$p.actual_duty_mean-[double]$p.target_duty)-gt0.12){$timingOk=$false}}
  $u10=$p10.sampler_util_mean_pct;$u40=$p40.sampler_util_mean_pct;$w10=$p10.sampler_power_mean_w;$w40=$p40.sampler_power_mean_w;$controlEffect=$false;if($null-ne$u10-and$null-ne$u40-and([double]$u40-[double]$u10)-ge8){$controlEffect=$true};if($null-ne$w10-and$null-ne$w40-and([double]$w40-[double]$w10)-ge6){$controlEffect=$true}
  $poolOk=(@($phases|Where-Object{[double]$_.pool_fraction-ge0.80}).Count-eq3);$threadControl=(@($phases|Where-Object{$null-ne$_.min_suspended_threads-and[int]$_.min_suspended_threads-gt0}).Count-eq3)
  $floor=$null;if($p10-in$productive){$floor=0.10}elseif($p25-in$productive){$floor=0.25}elseif($p40-in$productive){$floor=0.40}
  $cal=[ordered]@{schema_version='2.0';release=$Release;status=if($productive40-and$lowerProductive.Count-gt0-and$timingOk-and$controlEffect-and$poolOk-and$threadControl){'PASS'}else{'FAIL'};measurement_architecture='independent_nvidia_sampler_plus_phase_local_fresh_lolminer_hashrate_plus_measured_scheduler_duty';phases=@($phases);productive_at_40=$productive40;productive_lower_levels=@($lowerProductive|ForEach-Object{$_.target_duty});timing_matches_commanded_duty=$timingOk;measured_control_effect=$controlEffect;pool_connection_all_phases=$poolOk;thread_suspend_control=$threadControl;minimum_stable_productive_duty=$floor;decision='Is process suspend/resume a usable smooth background GPU actuator on this GTX1060?'}
  $cal|ConvertTo-Json -Depth 30|Set-Content -LiteralPath $calibrationFile -Encoding utf8
  if($cal.status-ne'PASS'){throw ('GPU independent-sampler calibration did not prove a usable productive control surface; result='+($cal|ConvertTo-Json -Compress -Depth 20))}
  Pass-LearningStage 'GPU_CALIBRATION_ACCEPTANCE' 'CONTROL_SURFACE_PASS' 'Independent sampler, fresh hashrate, actual timing, pool continuity and control effect passed.' @{minimum_stable_productive_duty=$floor;productive_lower_levels=@($cal.productive_lower_levels);timing_matches_commanded_duty=$timingOk;measured_control_effect=$controlEffect;pool_all=$poolOk;thread_control=$threadControl}

  $script:liveFloor=[double]$floor;$script:lastNonzeroDuty=0.40;$script:recoveryStable=0
  Write-LearningState 'GPU_LIVE' 'ENTER' 'GPU_LIVE_PROMOTED' 'GPU lane promoted only after measured control-surface PASS.' @{live_floor=$script:liveFloor;max_envelope=0.40}
  while($true){
    if(Test-Path -LiteralPath $stopMarker){break};if($miner.HasExited){throw ('lolMiner exited live code='+$miner.ExitCode)}
    $g=Get-NvidiaRow;$fg=Get-ForegroundEnginePct $miner.Id;$headroom=if($null-eq$fg){1.0}else{[Math]::Max(0.0,(100.0-[double]$fg)/100.0)};$desired=[Math]::Min(0.40,0.40*$headroom)
    $hard=$false;if($g.ok){$free=[double]$g.memory_total_mb-[double]$g.memory_used_mb;if(($null-ne$g.temp_c-and[double]$g.temp_c-ge75)-or$free-lt512){$hard=$true}}
    if($hard-or$desired-lt$liveFloor){$target=0.0;$null=$script:dutyController.Suspend();$script:recoveryStable=0}else{
      $target=[Math]::Max($liveFloor,$desired)
      if($target-lt$lastNonzeroDuty){$script:lastNonzeroDuty=$target;$script:recoveryStable=0}else{$script:recoveryStable++;if($script:recoveryStable-lt6){$target=[Math]::Min($target,$lastNonzeroDuty)}else{$script:lastNonzeroDuty=[Math]::Min(0.40,$lastNonzeroDuty+0.05);$target=[Math]::Min($target,$lastNonzeroDuty);$script:recoveryStable=0}}
    }
    if($target-gt0){[void](Run-DutyCycle $target 'LIVE_CONTINUOUS_GPU_GOVERNOR' 1000 $false)}else{$net=Get-NetworkState $miner.Id;$hashObs=Get-LolHashrateObservation $null;$row=[ordered]@{utc=(Get-Date).ToUniversalTime().ToString('o');release=$Release;session_id=$sessionId;mode='LIVE_PAUSED_BELOW_CALIBRATED_FLOOR_OR_SAFETY';normalized_duty_target=0.0;actual_awake_ms=0.0;actual_duty_fraction=0.0;gpu=$g;foreground_gpu=$fg;network=$net;hashrate_mhs=$hashObs.mhs;hashrate_source=$hashObs.source;miner_alive=(-not$miner.HasExited);suspended_threads=$script:dutyController.SuspendedThreadCount};Add-Row $row;$script:loopSamples++;Write-Health 'LIVE_PAUSED_BELOW_CALIBRATED_FLOOR_OR_SAFETY' 0.0 $g $fg $net $true $hashObs.mhs $hashObs.source;Start-Sleep -Milliseconds 1000}
  }
}finally{Write-LearningState 'GPU_RUNTIME_TERMINATION' 'ENTER' 'SUPERVISOR_EXITING' 'GPU supervisor is leaving its runtime loop; cleanup follows.' @{loop_samples=$script:loopSamples};if($null-ne$script:sampler){Stop-GpuSampler $script:sampler};if($null-ne$script:dutyController){try{$script:dutyController.ResumeAll()}catch{}};if($null-ne$miner){Stop-Miner $miner};try{Close-Segment (Get-Date).ToUniversalTime() 'SUPERVISOR_STOP'}catch{};Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath $minerPidFile -Force -ErrorAction SilentlyContinue}
'@

$script:StopPayload=@'
param([string]$Root='D:\MiningSniper')
$ErrorActionPreference='Stop'
$state=Join-Path $Root 'PROTECTED_STATE\Beta\GPU_LANE_R065_RC16';[IO.Directory]::CreateDirectory($state)|Out-Null;Set-Content -LiteralPath (Join-Path $state 'STOP_REQUESTED_GPU_R065') -Value ((Get-Date).ToUniversalTime().ToString('o')) -Encoding ascii
Write-Host 'GPU stop requested. CPU R063 RC6 is not touched.'
'@
$script:StatusPayload=@'
param([string]$Root='D:\MiningSniper')
$h=Join-Path $Root 'PROTECTED_STATE\Beta\GPU_LANE_R065_RC16\RUNTIME_HEALTH.json';if(Test-Path -LiteralPath $h){Get-Content -Raw -LiteralPath $h}else{Write-Host 'GPU R065 RC16 health not found'}
'@
$script:ExportPayload=@'
param([string]$Root='D:\MiningSniper',[int]$Hours=24)
$ErrorActionPreference='Stop';$src=Join-Path $Root 'TELEMETRY\Beta\GPU_LANE_R065_RC16';$out=Join-Path $Root 'GENERATED\GPU_LANE_R065_RC16';[IO.Directory]::CreateDirectory($out)|Out-Null;$cut=(Get-Date).ToUniversalTime().AddHours(-$Hours);$files=@(Get-ChildItem -LiteralPath (Join-Path $src 'RAW') -Recurse -File -Filter '*.jsonl' -ErrorAction SilentlyContinue|Where-Object{$_.LastWriteTimeUtc-ge$cut});$zip=Join-Path $out ('MiningSniper_GPU_R065_RC16_TELEMETRY_'+(Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')+'.zip');$tmp=Join-Path $out ('export_'+[guid]::NewGuid().ToString('N'));[IO.Directory]::CreateDirectory($tmp)|Out-Null;try{foreach($f in$files){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $tmp $f.Name)};$cal=Join-Path $Root 'PROTECTED_STATE\Beta\GPU_LANE_R065_RC16\CALIBRATION_RESULT.json';if(Test-Path -LiteralPath $cal){Copy-Item -LiteralPath $cal -Destination (Join-Path $tmp 'CALIBRATION_RESULT.json')};Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $zip -Force;Write-Host $zip}finally{Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue}
'@

function Get-Sha256([string]$Path){(Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()}
function Read-Json([string]$Path){Get-Content -Raw -LiteralPath $Path|ConvertFrom-Json}
function Get-FreeApiPort([int[]]$Preferred){foreach($p in$Preferred){$used=Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue;if($null-eq$used){return$p}};throw 'No free GPU API port in 18081..18089'}
function Get-CpuHealthAge([string]$HealthPath){if(-not(Test-Path -LiteralPath $HealthPath)){return[double]::PositiveInfinity};try{return((Get-Date).ToUniversalTime()-(Get-Item -LiteralPath $HealthPath).LastWriteTimeUtc).TotalSeconds}catch{return[double]::PositiveInfinity}}
function Test-PidAlive([string]$PidPath,[string]$ExpectedName){if(-not(Test-Path -LiteralPath $PidPath)){return$false};try{$p=[int](Get-Content -Raw -LiteralPath $PidPath);$proc=Get-Process -Id $p -ErrorAction Stop;if($ExpectedName-and$proc.ProcessName-ne$ExpectedName){return$false};return$true}catch{return$false}}
function Write-Activation([string]$Path,[hashtable]$Data){$tmp=$Path+'.tmp';$Data|ConvertTo-Json -Depth 50|Set-Content -LiteralPath $tmp -Encoding utf8;Move-Item -LiteralPath $tmp -Destination $Path -Force}
function Start-BackgroundPwsh([string]$ScriptPath,[string[]]$Arguments,[string]$StdOut,[string]$StdErr){$quoted=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$ScriptPath)+$Arguments;return Start-Process -FilePath 'pwsh.exe' -ArgumentList $quoted -PassThru -WindowStyle Hidden -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr}
function Get-CurrentFileHash([string]$Path){if(Test-Path -LiteralPath $Path){return(Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()};return$null}

$Release='GPU_LANE_R065_RC16';$learningBasePath=Join-Path $Root 'MININGSNIPER_LEARNING_BASE.json';$learningDir=Join-Path $Root 'LEARNING';$learningModulePath=Join-Path $learningDir 'MiningSniper.Learning.psm1';$learningJournalPath=Join-Path $Root 'PROTECTED_STATE\Learning\LEARNING_EVENTS.jsonl'
$generatedDir=Join-Path $Root 'GENERATED\GPU_LANE_R065_RC16';$stage=Join-Path $Root 'STAGING\GPU_LANE_R065_RC16';$betaDir=Join-Path $Root 'Beta\R065_GPU_RC16';$stateDir=Join-Path $Root 'PROTECTED_STATE\Beta\GPU_LANE_R065_RC16';$telemetry=Join-Path $Root 'TELEMETRY\Beta\GPU_LANE_R065_RC16';foreach($d in@($generatedDir,$stage,$stateDir,$telemetry)){[IO.Directory]::CreateDirectory($d)|Out-Null}
$activationPath=Join-Path $generatedDir 'ACTIVATION_REPORT_GPU_R065_RC16.json';$activation=[ordered]@{schema_version='1.0';release=$Release;started_utc=(Get-Date).ToUniversalTime().ToString('o');status='STARTING';gpu_started=$false;gpu_active=$false;cpu_rc6_untouched=$true;checks=[ordered]@{};learning=[ordered]@{};error=$null}
Write-Activation $activationPath $activation

$learningRunId=([guid]::NewGuid().ToString('N'))
$script:learningAvailable=$false;$script:currentLearningStage=$null
function Write-BootstrapLearningEvent([hashtable]$Event){
  [IO.Directory]::CreateDirectory((Split-Path -Parent $learningJournalPath))|Out-Null
  $json=($Event|ConvertTo-Json -Compress -Depth 50)+[Environment]::NewLine
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes($json)
  $fs=[IO.FileStream]::new($learningJournalPath,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read,4096,[IO.FileOptions]::WriteThrough)
  try{$fs.Write($bytes,0,$bytes.Length);$fs.Flush($true)}finally{$fs.Dispose()}
}
function New-BootstrapEvent([string]$EventType,[string]$Stage,[string]$Outcome,[string]$Decision,[string]$ReasonCode,[string]$ReasonText,[hashtable]$Evidence=@{},[hashtable]$Components=@{}){
  $seq=1L;if(Test-Path -LiteralPath $learningJournalPath){foreach($line in[IO.File]::ReadLines($learningJournalPath)){if([string]::IsNullOrWhiteSpace($line)){continue};try{$o=$line|ConvertFrom-Json;if([long]$o.runtime_seq-ge$seq){$seq=[long]$o.runtime_seq+1}}catch{}}}
  return[ordered]@{event_id=[guid]::NewGuid().ToString('N');run_id=$learningRunId;runtime_seq=$seq;utc=[DateTimeOffset]::Now.ToString('o');writer_version='bootstrap-1.0';source='SCRIPT_BOOTSTRAP';release=$Release;event_type=$EventType;stage=$Stage;outcome=$Outcome;decision=$Decision;reason_code=$ReasonCode;reason_text=$ReasonText;component_outcomes=$Components;evidence=$Evidence;root_cause_status='OBSERVED_ONLY';root_cause_or_unknown='UNKNOWN_FROM_RUNTIME'}
}
function Start-MainLearningStage([string]$Stage,[string]$Decision,[hashtable]$Evidence=@{}){
  $script:currentLearningStage=$Stage
  if($script:learningAvailable){Write-MiningSniperLearningStep -ProjectRoot $Root -RunId $learningRunId -Release $Release -StepId $Stage -Outcome START -Decision $Decision -ReasonCode 'STEP_ENTER' -ReasonText 'Entering decision-critical activation stage.' -Evidence $Evidence|Out-Null}
  else{Write-BootstrapLearningEvent (New-BootstrapEvent 'STEP_START' $Stage 'START' $Decision 'STEP_ENTER' 'Entering decision-critical activation stage.' $Evidence)}
}
function Pass-MainLearningStage([string]$Stage,[string]$Decision,[string]$ReasonCode,[string]$ReasonText,[hashtable]$Evidence=@{},[hashtable]$Components=@{}){
  if($script:learningAvailable){Write-MiningSniperLearningStep -ProjectRoot $Root -RunId $learningRunId -Release $Release -StepId $Stage -Outcome PASS -Decision $Decision -ReasonCode $ReasonCode -ReasonText $ReasonText -Evidence $Evidence -ComponentOutcomes $Components|Out-Null}
  else{Write-BootstrapLearningEvent (New-BootstrapEvent 'STEP_PASS' $Stage 'PASS' $Decision $ReasonCode $ReasonText $Evidence $Components)}
  $script:currentLearningStage=$null
}

try{
  if(-not(Test-Path -LiteralPath $learningBasePath -PathType Leaf)){throw 'Canonical MININGSNIPER_LEARNING_BASE.json missing from project root'}
  $baseBefore=Get-Content -Raw -LiteralPath $learningBasePath|ConvertFrom-Json
  $baseShaBefore=Get-Sha256 $learningBasePath
  if([string]$baseBefore.schema-ne'miningsniper-learning-base/v1'){throw 'Learning base schema unsupported'}
  if([int]$baseBefore.learning_revision-lt1){throw 'Learning base revision invalid'}
  $semanticCountBefore=@($baseBefore.event_log).Count

  # Raw fact exists before learning-module install, generated runtime or GPU activity.
  $startEvent=New-BootstrapEvent 'RUN_START' 'RUN' 'STARTED' 'Activate learning-integrated GPU duty-control candidate' 'USER_EXPLICIT_RUNTIME_REOPEN' 'User explicitly requested a new release; runtime facts are journaled before GPU actions.' @{
    entry_point='RUN_ACTIVATE_R065_GPU_LANE_RC16.ps1'
    project_root=$Root
    process_id=$PID
    pwsh=$PSVersionTable.PSVersion.ToString()
    base_sha256_before=$baseShaBefore
    decision_under_test='Does the repaired fractional duty scheduler create a productive measurable 10/25/40 control surface?'
    already_proven='GTX1060 lolMiner Etchash pool bootstrap'
  }
  Write-BootstrapLearningEvent $startEvent
  $activation.learning.run_id=$learningRunId;$activation.learning.base=$learningBasePath;$activation.learning.journal=$learningJournalPath;$activation.learning.bootstrap_run_start='DURABLE';Write-Activation $activationPath $activation

  Start-MainLearningStage 'LEARNING_BOOTSTRAP' 'Install/validate runtime learning writer and replay durable journal into canonical base'
  [IO.Directory]::CreateDirectory($learningDir)|Out-Null
  Set-Content -LiteralPath $learningModulePath -Value $script:LearningModulePayload -Encoding utf8
  $mtok=$null;$merr=$null;[void][Management.Automation.Language.Parser]::ParseFile($learningModulePath,[ref]$mtok,[ref]$merr);if($merr.Count-gt0){throw ('Learning module parse failure: '+(($merr|ForEach-Object{$_.Message})-join'; '))}
  Import-Module $learningModulePath -Force

  # Test writer against an isolated copy of the user's actual canonical schema, not a toy object.
  $selfRoot=Join-Path ([IO.Path]::GetTempPath()) ('MiningSniperLearningSchemaSelfTest_'+[guid]::NewGuid().ToString('N'))
  [IO.Directory]::CreateDirectory($selfRoot)|Out-Null
  try{
    Copy-Item -LiteralPath $learningBasePath -Destination (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json') -Force
    $orig=Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json')|ConvertFrom-Json
    $origSemantic=@($orig.event_log).Count
    $testRun='schema_'+[guid]::NewGuid().ToString('N')
    Write-MiningSniperLearningEvent -ProjectRoot $selfRoot -RunId $testRun -Release 'LEARNING_SELFTEST' -EventType 'RUN_START' -Stage 'RUN' -Outcome 'STARTED' -Decision 'schema parity' -ReasonCode 'SELFTEST' -ReasonText 'actual base schema writer selftest'|Out-Null
    Write-MiningSniperLearningEvent -ProjectRoot $selfRoot -RunId $testRun -Release 'LEARNING_SELFTEST' -EventType 'STEP_PASS' -Stage 'A' -Outcome 'PASS' -Decision 'journal replay' -ReasonCode 'SELFTEST_PASS' -ReasonText 'normal append/replay' -Evidence @{probe=42}|Out-Null
    $b1=Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json')|ConvertFrom-Json
    if(@($b1.event_log).Count-ne$origSemantic){throw 'Learning selftest changed semantic event_log history'}
    $beforeCount=@($b1.runtime_event_log).Count
    Sync-MiningSniperLearningBase -ProjectRoot $selfRoot|Out-Null
    $b2=Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json')|ConvertFrom-Json
    if(@($b2.runtime_event_log).Count-ne$beforeCount){throw 'Learning replay duplicated event_id'}

    # Crash window: append durable journal event without base sync; next sync must recover exactly once.
    $testPaths=Get-MsLearningPaths -ProjectRoot $selfRoot
    $next=1L;foreach($r in@(Read-MsJournalRecords -JournalPath $testPaths.Journal)){if([long]$r.runtime_seq-ge$next){$next=[long]$r.runtime_seq+1}}
    $crash=New-MsOrderedEvent -RunId $testRun -RuntimeSeq $next -Release 'LEARNING_SELFTEST' -EventType 'STEP_FAIL' -Stage 'CRASH_WINDOW' -Outcome 'FAIL' -Decision 'recover unsynced WAL event' -ReasonCode 'SIMULATED_CRASH' -ReasonText 'durable journal only'
    Write-MsJournalRecordDurable -JournalPath $testPaths.Journal -Record $crash
    $preCrash=Get-Content -Raw -LiteralPath $testPaths.Base|ConvertFrom-Json
    if(@($preCrash.runtime_event_log|Where-Object{$_.event_id-eq$crash.event_id}).Count-ne0){throw 'Crash-window selftest event reached base before sync'}
    Sync-MiningSniperLearningBase -ProjectRoot $selfRoot|Out-Null
    $postCrash=Get-Content -Raw -LiteralPath $testPaths.Base|ConvertFrom-Json
    if(@($postCrash.runtime_event_log|Where-Object{$_.event_id-eq$crash.event_id}).Count-ne1){throw 'Crash-window replay did not recover exactly once'}

    # Torn tail: corrupt last partial line, then writer must insert separator and preserve next valid event.
    $fs=[IO.FileStream]::new($testPaths.Journal,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read,4096,[IO.FileOptions]::WriteThrough);try{$junk=[Text.UTF8Encoding]::new($false).GetBytes('{"event_id":"TORN');$fs.Write($junk,0,$junk.Length);$fs.Flush($true)}finally{$fs.Dispose()}
    $next=1L;foreach($r in@(Read-MsJournalRecords -JournalPath $testPaths.Journal)){if([long]$r.runtime_seq-ge$next){$next=[long]$r.runtime_seq+1}}
    $afterTorn=New-MsOrderedEvent -RunId $testRun -RuntimeSeq $next -Release 'LEARNING_SELFTEST' -EventType 'STEP_PASS' -Stage 'TORN_TAIL_RECOVERY' -Outcome 'PASS' -Decision 'append after torn tail' -ReasonCode 'SELFTEST_PASS' -ReasonText 'valid event after corrupt tail'
    Write-MsJournalRecordDurable -JournalPath $testPaths.Journal -Record $afterTorn
    Sync-MiningSniperLearningBase -ProjectRoot $selfRoot|Out-Null
    $postTorn=Get-Content -Raw -LiteralPath $testPaths.Base|ConvertFrom-Json
    if(@($postTorn.runtime_event_log|Where-Object{$_.event_id-eq$afterTorn.event_id}).Count-ne1){throw 'Torn-tail recovery lost next valid event'}
  }finally{Remove-Item -LiteralPath $selfRoot -Recurse -Force -ErrorAction SilentlyContinue}

  $sync0=Sync-MiningSniperLearningBase -ProjectRoot $Root
  $script:learningAvailable=$true
  $activation.learning.writer_version='1.2';$activation.learning.actual_base_schema_selftest='PASS';$activation.learning.crash_window_replay='PASS';$activation.learning.torn_tail_recovery='PASS';$activation.learning.initial_sync_added=[int]$sync0.added
  Pass-MainLearningStage 'LEARNING_BOOTSTRAP' 'Install/validate runtime learning writer and replay durable journal into canonical base' 'LEARNING_STORE_PASS' 'Learning writer parsed/imported, durable journal replay is idempotent, simulated crash-window replay recovered, and append after a torn journal tail preserved the next valid event.' @{
    writer_version='1.2'
    actual_base_schema_selftest='PASS'
    source_base_sha256=$baseShaBefore
    base_path=$learningBasePath
    journal_path=$learningJournalPath
    module_path=$learningModulePath
    initial_sync_added=[int]$sync0.added
    selftest_compiled_events=6
    crash_window_replay=$true
    torn_tail_recovery=$true
  }

  Start-MainLearningStage 'RC14_DUTY_ROOT_CAUSE_FIXTURE' 'Execute exact delivered duty functions without GPU/miner and prove RC14 zero-duty mechanism plus repaired 10/25/40 schedule'
  $stok=$null;$serr=$null
  $supInputAst=[Management.Automation.Language.Parser]::ParseInput($script:SupervisorPayload,[ref]$stok,[ref]$serr)
  if($serr.Count-gt0){throw ('Supervisor payload parse failure before duty fixture: '+(($serr|ForEach-Object{$_.Message})-join'; '))}
  $dutyFixture=Join-Path $stage 'DUTY_BEHAVIOR_EXACT_SELFTEST.ps1'
  $dutyFixtureResult=Join-Path $generatedDir 'DUTY_BEHAVIOR_EXACT_SELFTEST_RESULT.json'

  # The complete child is a prevalidated final artifact payload. Do not assemble executable children
  # from fragments after delivery. Compare its decision-critical functions with the supervisor first.
  $ftok=$null;$ferr=$null
  $fixtureAst=[Management.Automation.Language.Parser]::ParseInput($script:DutyFixturePayload,[ref]$ftok,[ref]$ferr)
  if($ferr.Count-gt0){throw ('Duty fixture payload parse failure: '+(($ferr|ForEach-Object{$_.Message})-join'; '))}
  $firstFixtureLine=($script:DutyFixturePayload -split "`r?`n"|Where-Object{-not[string]::IsNullOrWhiteSpace($_)}|Select-Object -First 1).Trim()
  if(-not$firstFixtureLine.StartsWith('param(')){throw ('GENERATED-CHILD-ENTRY-PARAM-FIRST-V2 failed: '+$firstFixtureLine)}

  $supDutyFns=@($supInputAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and ($node.Name-eq'Get-DutySchedule' -or $node.Name-eq'Invoke-DutyWindow')},$true))
  $fixDutyFns=@($fixtureAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and ($node.Name-eq'Get-DutySchedule' -or $node.Name-eq'Invoke-DutyWindow')},$true))
  foreach($fnName in @('Get-DutySchedule','Invoke-DutyWindow')){
    $sf=@($supDutyFns|Where-Object{$_.Name-eq$fnName}|Select-Object -First 1)
    $ff=@($fixDutyFns|Where-Object{$_.Name-eq$fnName}|Select-Object -First 1)
    if($sf.Count-ne1-or$ff.Count-ne1){throw ('TRANSITIVE-EXECUTABLE-ARTIFACT-GATE-V1 missing function '+$fnName)}
    $sn=($sf[0].Extent.Text -replace '\s+',' ').Trim()
    $fn=($ff[0].Extent.Text -replace '\s+',' ').Trim()
    if($sn-ne$fn){throw ('TRANSITIVE-EXECUTABLE-ARTIFACT-GATE-V1 function drift '+$fnName)}
  }

  Set-Content -LiteralPath $dutyFixture -Value $script:DutyFixturePayload -Encoding utf8
  $ctok=$null;$cerr=$null
  [void][Management.Automation.Language.Parser]::ParseFile($dutyFixture,[ref]$ctok,[ref]$cerr)
  if($cerr.Count-gt0){throw ('Generated duty child ParseFile failed: '+(($cerr|ForEach-Object{$_.Message})-join'; '))}

  $fixtureOut=@(& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $dutyFixture -ResultPath $dutyFixtureResult 2>&1)
  $fixtureRc=$LASTEXITCODE
  if($fixtureRc-ne0-or-not($fixtureOut-contains'DUTY_BEHAVIOR_EXACT_SELFTEST_PASS')-or-not(Test-Path -LiteralPath $dutyFixtureResult)){
    throw ('DUTY-BEHAVIOR-EXEC-FIXTURE-V3 failed rc='+$fixtureRc+' output='+(($fixtureOut|ForEach-Object{[string]$_})-join' | '))
  }
  $dutyProof=Get-Content -Raw -LiteralPath $dutyFixtureResult|ConvertFrom-Json
  $activation.duty_root_cause_fixture=$dutyProof
  Write-MiningSniperLearningEvent -ProjectRoot $Root -RunId $learningRunId -Release $Release -EventType 'COMPONENT_EVIDENCE' -Stage 'RC14_DUTY_ROOT_CAUSE' -Outcome 'PASS' -Decision 'Explain RC14 actual_duty_mean zero before any GPU start' -ReasonCode 'RC14_NUMERIC_OVERLOAD_REPRODUCED_AND_FIXED' -ReasonText 'Exact delivered fixture reproduced RC14 zero-duty arithmetic and proved repaired schedule/fake-controller timing.' -Evidence @{
    rc14_old_d10=[int]$dutyProof.rc14_old_active_ms.d10
    rc14_old_d25=[int]$dutyProof.rc14_old_active_ms.d25
    rc14_old_d40=[int]$dutyProof.rc14_old_active_ms.d40
    repaired_d10=[int]$dutyProof.repaired_schedule_active_ms.'0.1'
    repaired_d25=[int]$dutyProof.repaired_schedule_active_ms.'0.25'
    repaired_d40=[int]$dutyProof.repaired_schedule_active_ms.'0.4'
  }|Out-Null
  Pass-MainLearningStage 'RC14_DUTY_ROOT_CAUSE_FIXTURE' 'Execute exact delivered duty functions without GPU/miner and prove RC14 zero-duty mechanism plus repaired 10/25/40 schedule' 'DUTY_FIXTURE_PASS' 'Exact generated duty behavior fixture passed before GPU activity.' @{old_10=[int]$dutyProof.rc14_old_active_ms.d10;old_25=[int]$dutyProof.rc14_old_active_ms.d25;old_40=[int]$dutyProof.rc14_old_active_ms.d40;new_10=[int]$dutyProof.repaired_schedule_active_ms.'0.1';new_25=[int]$dutyProof.repaired_schedule_active_ms.'0.25';new_40=[int]$dutyProof.repaired_schedule_active_ms.'0.4'}

  Start-MainLearningStage 'CPU_RC6_COEXISTENCE_PRE' 'Prove active CPU RC6 by independent supervisor, miner and advancing fresh health; HTTP API advisory only'
  $cpuState=Join-Path $Root 'PROTECTED_STATE\Beta\PilotA_R063_RC6';$cpuHealth=Join-Path $cpuState 'RUNTIME_HEALTH.json';$cpuSupervisorPid=Join-Path $cpuState 'supervisor.pid';$cpuMinerPid=Join-Path $cpuState 'xmrig.pid'
  if(-not(Test-PidAlive $cpuSupervisorPid 'pwsh')){throw 'R063 RC6 supervisor is not alive'};if(-not(Test-PidAlive $cpuMinerPid 'xmrig')){throw 'R063 RC6 xmrig is not alive'};if(-not(Test-Path -LiteralPath $cpuHealth)){throw 'R063 RC6 health file missing'}
  $h1=Read-Json $cpuHealth;if([string]$h1.mode-ne'ACTIVE_CONTINUOUS'){throw ('R063 RC6 mode is '+[string]$h1.mode+', expected ACTIVE_CONTINUOUS')};$age1=Get-CpuHealthAge $cpuHealth;if($age1-gt30){throw ('R063 RC6 health stale age_s='+[Math]::Round($age1,3))};Start-Sleep -Seconds 7;$h2=Read-Json $cpuHealth;$age2=Get-CpuHealthAge $cpuHealth;if([int]$h2.loop_samples-le[int]$h1.loop_samples-or$age2-gt30){throw 'R063 RC6 health did not advance/freshen during coexistence proof'}
  $cpuApiAdvisory='NOT_TESTED';try{$p=[int]$h2.api_port;$null=Invoke-RestMethod -Uri ("http://127.0.0.1:$p/2/summary") -TimeoutSec 3;$cpuApiAdvisory='PASS'}catch{$cpuApiAdvisory='ADVISORY_FAIL'};$activation.checks.cpu_rc6_coexistence=[ordered]@{status='PASS';mode=$h2.mode;supervisor_pid=[int](Get-Content -Raw -LiteralPath $cpuSupervisorPid);miner_pid=[int](Get-Content -Raw -LiteralPath $cpuMinerPid);loop_before=[int]$h1.loop_samples;loop_after=[int]$h2.loop_samples;health_age_s=[Math]::Round($age2,3);api=$cpuApiAdvisory};Pass-MainLearningStage 'CPU_RC6_COEXISTENCE_PRE' 'Prove active CPU RC6 by independent supervisor, miner and advancing fresh health; HTTP API advisory only' 'CPU_RC6_COEXISTENCE_PASS' 'CPU RC6 supervisor/miner live and health advanced; API is advisory.' @{mode=[string]$h2.mode;loop_before=[int]$h1.loop_samples;loop_after=[int]$h2.loop_samples;health_age_s=[double]$age2;api=$cpuApiAdvisory}

  Start-MainLearningStage 'NVIDIA_TELEMETRY_PRECHECK' 'Prove GTX1060 NVIDIA telemetry before GPU candidate start'
  $smi=$null;$cmd=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue;if($cmd){$smi=$cmd.Source};if($null-eq$smi){foreach($p in@("$env:ProgramW6432\NVIDIA Corporation\NVSMI\nvidia-smi.exe","$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe")){if(Test-Path -LiteralPath $p){$smi=$p;break}}};if($null-eq$smi){throw 'nvidia-smi.exe not found'};$smiOut=&$smi '--query-gpu=index,name,utilization.gpu,memory.total,memory.used,temperature.gpu,power.draw,pstate' '--format=csv,noheader,nounits' 2>&1;if($LASTEXITCODE-ne0){throw ('nvidia-smi preflight failed: '+(($smiOut|ForEach-Object{[string]$_})-join' | '))};$gpuLine=@($smiOut|Where-Object{$_-is[string]-and$_ -match '^\s*\d+\s*,'})|Select-Object -First 1;if($null-eq$gpuLine){throw 'No NVIDIA GPU row'};if([string]$gpuLine-notmatch'GTX 1060'){throw ('Unexpected GPU: '+$gpuLine)};$activation.checks.nvidia_telemetry=[ordered]@{status='PASS';backend=$smi;row=[string]$gpuLine};Pass-MainLearningStage 'NVIDIA_TELEMETRY_PRECHECK' 'Prove GTX1060 NVIDIA telemetry before GPU candidate start' 'NVIDIA_TELEMETRY_PASS' 'GTX1060 telemetry backend returned a parseable row.' @{backend=$smi;row=[string]$gpuLine}

  Start-MainLearningStage 'LOLMINER_PROVENANCE' 'Acquire exact official clean lolMiner 1.98a artifact without copying unrelated drivers'
  $repo='Lolliedieb/lolMiner-releases';$tag='1.98a';$assetName='lolMiner_v1.98a_Win64_cln.zip';$pinned='c92f9c6e3e3176a90f19aef27abe70534c19b3e7ba5b5c2756d93f3495585809';$api='https://api.github.com/repos/'+$repo+'/releases/tags/'+$tag;$gh=Invoke-RestMethod -Uri $api -Headers @{'User-Agent'='MiningSniper-R065-RC16';'Accept'='application/vnd.github+json'};$asset=$gh.assets|Where-Object{$_.name-eq$assetName}|Select-Object -First 1;if($null-eq$asset){throw 'Official lolMiner clean asset not found'};$digest=[string]$asset.digest;if($digest-ne('sha256:'+$pinned)){throw ('Official GitHub digest changed/unexpected: '+$digest)};$archive=Join-Path $stage $assetName;Invoke-WebRequest -Uri ([string]$asset.browser_download_url) -OutFile $archive -Headers @{'User-Agent'='MiningSniper-R065-RC16'};if(-not(Test-Path -LiteralPath $archive)){throw 'lolMiner archive download missing'};$hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant();if($hash-ne$pinned){throw 'lolMiner clean archive SHA256 mismatch'};$activation.lolminer_asset=[ordered]@{tag=$tag;asset=$assetName;sha256=$hash;github_digest=$digest};$activation.checks.lolminer_provenance='PASS'
  $extract=Join-Path $stage 'lolminer_extract';if(Test-Path -LiteralPath $extract){Remove-Item -LiteralPath $extract -Recurse -Force};Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force;$exe=Get-ChildItem -LiteralPath $extract -Recurse -File -Filter 'lolMiner.exe'|Select-Object -First 1;if($null-eq$exe){throw 'lolMiner.exe missing from clean archive'};$minerDir=Join-Path $betaDir 'miner';[IO.Directory]::CreateDirectory($minerDir)|Out-Null;$lol=Join-Path $minerDir 'lolMiner.exe';Copy-Item -LiteralPath $exe.FullName -Destination $lol -Force;$expectedLol=(Get-FileHash -Algorithm SHA256 -LiteralPath $exe.FullName).Hash.ToLowerInvariant();if((Get-FileHash -Algorithm SHA256 -LiteralPath $lol).Hash.ToLowerInvariant()-ne$expectedLol){throw 'lolMiner executable copy hash mismatch'}
  $allow=@('lolMiner.exe');$copied=@(Get-ChildItem -LiteralPath $minerDir -File|ForEach-Object{$_.Name});if(@($copied|Where-Object{$_-notin$allow}).Count-gt0){throw 'GPU miner allowlist violation'};if(Get-ChildItem -LiteralPath $minerDir -Recurse -File|Where-Object{$_.Name-match'(?i)WinRing0|\.sys$'}){throw 'Forbidden driver artifact in GPU miner directory'};$activation.checks.allowlist='PASS';Pass-MainLearningStage 'LOLMINER_PROVENANCE' 'Acquire exact official clean lolMiner 1.98a artifact without copying unrelated drivers' 'LOLMINER_PROVENANCE_PASS' 'Official clean archive digest and executable allowlist passed.' @{tag=$tag;archive_sha256=$hash;exe_sha256=$expectedLol;allowlist=@($copied)}

  Start-MainLearningStage 'LOLMINER_HOST_COMPATIBILITY' 'Prove delivered lolMiner binary exposes expected Etchash capability on this host'
  $helpOut=@(&$lol '--help' 2>&1);$helpText=(($helpOut|ForEach-Object{[string]$_})-join"`n");if($helpText-notmatch'(?i)ETCHASH'){throw 'Delivered lolMiner does not expose Etchash'};$activation.checks.etchash='PASS';Pass-MainLearningStage 'LOLMINER_HOST_COMPATIBILITY' 'Prove delivered lolMiner binary exposes expected Etchash capability on this host' 'LOLMINER_ETCHASH_CAPABILITY_PASS' 'Delivered binary exposes Etchash.' @{lolminer=$lol}

  Start-MainLearningStage 'GENERATED_RUNTIME_GATES' 'Parse exact generated runtime and execute parser/scope/schema/calibration regression guards before GPU start'
  $apiPort=Get-FreeApiPort @(18081,18082,18083,18084,18085,18086,18087,18088,18089);$lolLog=Join-Path $stateDir 'lolminer_native.log';Remove-Item -LiteralPath $lolLog -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath (Join-Path $stateDir 'STOP_REQUESTED_GPU_R065') -Force -ErrorAction SilentlyContinue
  $supervisor=Join-Path $betaDir 'GPU_GOVERNOR_R065_RC16.ps1';$stop=Join-Path $betaDir 'STOP_GPU_R065_RC16.ps1';$status=Join-Path $betaDir 'STATUS_GPU_R065_RC16.ps1';$export=Join-Path $betaDir 'EXPORT_GPU_R065_RC16_TELEMETRY.ps1';Set-Content -LiteralPath $supervisor -Value $script:SupervisorPayload -Encoding utf8;Set-Content -LiteralPath $stop -Value $script:StopPayload -Encoding utf8;Set-Content -LiteralPath $status -Value $script:StatusPayload -Encoding utf8;Set-Content -LiteralPath $export -Value $script:ExportPayload -Encoding utf8
  foreach($ps in@($supervisor,$stop,$status,$export)){$tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($ps,[ref]$tok,[ref]$err);if($err.Count-gt0){throw ('Generated PowerShell parse failure '+$ps+': '+(($err|ForEach-Object{$_.Message})-join'; '))}}
  if(Select-String -LiteralPath $supervisor -Pattern 'WinRing0|Add-MpPreference|Set-MpPreference|--pl|--cclk|--mclk|--coff|--moff' -Quiet){throw 'Forbidden GPU runtime token'}
  $astTok=$null;$astErr=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($supervisor,[ref]$astTok,[ref]$astErr)
  $reserved=@('PID','Host','HOME','PSScriptRoot','PSCommandPath','MyInvocation','PSVersionTable','Error','Args','Input','Matches','NestedPromptLevel','ShellId','This','ExecutionContext','StackTrace','PSItem','_')
  $badParams=[Collections.Generic.List[string]]::new();$params=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.ParameterAst]},$true));foreach($p in$params){$n=$p.Name.VariablePath.UserPath;if($reserved-contains$n){$badParams.Add($n)}};if($badParams.Count-gt0){throw ('Generated PowerShell automatic-variable parameter collision(s): '+(($badParams|Sort-Object -Unique)-join', '))}
  $defs=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]},$true)|ForEach-Object{$_.Name});$requiredInternal=@('Parse-Num','Find-NvidiaSmi','Get-NvidiaRow','Get-ForegroundEnginePct','Get-HeartbeatMs','Get-LolApi','Convert-LolApiHashrateMhs','Parse-LolHashrateLine','Get-LolHashrateObservation','Get-NativeLogTail','Get-NetworkState','Test-Pool20128','Start-Miner','Attach-DutyController','Stop-Miner','Day-Dirs','Start-Segment','Close-Segment','Add-Row','Write-Health','Run-ProductiveBootstrap','Get-DutySchedule','Invoke-DutyWindow','Run-DutyCycle','Median','Average','Get-LineCount','Get-LinesSince','Get-FreshLogHashratesSince','Start-GpuSampler','Stop-GpuSampler','Parse-SamplerRowsSince','Get-ApiEtchashSnapshot','Measure-DutyPhase','Start-LearningStage','Pass-LearningStage','Write-LearningState');$missing=@($requiredInternal|Where-Object{$_-notin$defs});if($missing.Count-gt0){throw ('PS-CUSTOM-SYMBOL-CLOSURE-V1 missing internal helper definitions: '+($missing-join', '))}
  $text=Get-Content -Raw -LiteralPath $supervisor
  if([regex]::IsMatch($text,'(?i)(?<!script:)\$duty\.(Suspend|Resume|SuspendedThreadCount)')){throw 'DUTY-CONTROLLER-SCOPE-V1: unqualified duty controller call remains'}
  if([regex]::IsMatch($text,'(?i)function\s+Measure-DutyPhase\s*\(\s*\[double\]\$Duty(?:\W|$)')){throw 'DUTY-CONTROLLER-SCOPE-V1: phase parameter Duty collides with controller concept'}
  if($text-notmatch'\$script:dutyController'){throw 'DUTY-CONTROLLER-SCOPE-V1: explicit script dutyController missing'}
  foreach($retired in@('duty_weighted_util_proxy_pct','duty_weighted_power_proxy_w','median_active_util_pct','median_active_power_w','median_cycle_gpu_pct','median_cycle_power_w')){if($text-match[regex]::Escape($retired)){throw ('SINGLE-CURRENT-CALIBRATION-CONTRACT-V1: retired token '+$retired+' remains')}}
  foreach($required in@('--loop-ms=200','Get-FreshLogHashratesSince','Get-DutySchedule','Invoke-DutyWindow','actual_duty_fraction','Measure-DutyPhase 0.10','Measure-DutyPhase 0.25','Measure-DutyPhase 0.40','minimum_stable_productive_duty')){if($text-notmatch[regex]::Escape($required)){throw ('SINGLE-CURRENT-CALIBRATION-CONTRACT-V1: required token '+$required+' missing')}}
  if($text-match'(?i)function\s+Get-NetworkState\s*\(\s*\[int\]\s*\$Pid\b'){throw 'PS-AUTOMATIC-VARIABLE-PARAM-V1: reserved Pid returned'}
  if($text-notmatch'ok=\$false;pool_20128=\$false;pool_20128_any_state=\$false;connections=@\(\);error='){throw 'STABLE-RUNTIME-RESULT-SCHEMA-V1: network failure schema incomplete'}
  if($text-match'(?i)\.network\.pool_20128'){throw 'SAFE-OPTIONAL-PROPERTY-ACCESS-V1: direct nested pool access remains'}
  $hasAttachIndex=$text.IndexOf('Attach-DutyController $miner');$hasBootIndex=$text.IndexOf('$boot=Run-ProductiveBootstrap $miner');if($hasAttachIndex-lt0-or$hasBootIndex-lt0-or$hasAttachIndex-lt$hasBootIndex){throw 'MINER-BOOTSTRAP-BEFORE-DUTY-ACTUATOR-V1: duty attach occurs before productive bootstrap'}
  # Execute the exact delivered hashrate functions, not a regex about their source.
  $apiFn=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq'Convert-LolApiHashrateMhs'},$true));$logFn=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-eq'Parse-LolHashrateLine'},$true));if($apiFn.Count-ne1-or$logFn.Count-ne1){throw 'HASHRATE-DETECTOR-EXEC-FIXTURE-V1: exact function extraction failed'}
  $fixturePath=Join-Path $stage 'HASHRATE_DETECTOR_EXACT_SELFTEST.ps1'
  $fixtureBody=@'
$apiFixture=[pscustomobject]@{ok=$true;data=[pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239}}
$a=Convert-LolApiHashrateMhs $apiFixture
if($null-eq$a-or[Math]::Abs([double]$a-12.352733907856239)-gt0.000001){throw ('API fixture failed: '+[string]$a)}
$l=Parse-LolHashrateLine 'Average speed (5s): 17.89 Mh/s'
if($null-eq$l-or[Math]::Abs([double]$l-17.89)-gt0.000001){throw ('LOG fixture failed: '+[string]$l)}
Write-Output 'HASHRATE_DETECTOR_EXACT_SELFTEST_PASS'
'@
  $fixtureScript="param()`r`n`$ErrorActionPreference='Stop'`r`nSet-StrictMode -Version Latest`r`n"+$apiFn[0].Extent.Text+"`r`n"+$logFn[0].Extent.Text+"`r`n"+$fixtureBody
  Set-Content -LiteralPath $fixturePath -Value $fixtureScript -Encoding utf8
  $fixtureOut=@(& pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $fixturePath 2>&1);$fixtureRc=$LASTEXITCODE;if($fixtureRc-ne0-or-not($fixtureOut-contains'HASHRATE_DETECTOR_EXACT_SELFTEST_PASS')){throw ('HASHRATE-DETECTOR-EXEC-FIXTURE-V1 failed: '+(($fixtureOut|ForEach-Object{[string]$_})-join' | '))}
  $activation.checks.generated_runtime_gates='PASS';$activation.checks.hashrate_exact_fixture='PASS';$activation.checks.duty_exact_fixture='PASS';$activation.api_port=$apiPort;Write-Activation $activationPath $activation;Pass-MainLearningStage 'GENERATED_RUNTIME_GATES' 'Parse exact generated runtime and execute parser/scope/schema/calibration regression guards before GPU start' 'GENERATED_RUNTIME_GATES_PASS' 'Exact generated runtime parsed and decision-critical regression fixtures passed.' @{api_port=$apiPort;automatic_variable_collisions=0;missing_internal_symbols=0;hashrate_fixture='PASS';duty_fixture='PASS'}

  Start-MainLearningStage 'GPU_ACTIVATION' 'Start GPU supervisor, let it bootstrap, calibrate 10/25/40, and promote live only on measured control evidence'
  $supOut=Join-Path $generatedDir 'GPU_R065_RC16_SUPERVISOR.stdout.txt';$supErr=Join-Path $generatedDir 'GPU_R065_RC16_SUPERVISOR.stderr.txt';$sup=Start-BackgroundPwsh $supervisor @('-Root',$Root,'-StateDir',$stateDir,'-TelemetryRoot',$telemetry,'-GeneratedDir',$generatedDir,'-LolMinerExe',$lol,'-LolMinerLog',$lolLog,'-NvidiaSmi',$smi,'-ApiPort',[string]$apiPort,'-PoolHost','gulf.moneroocean.stream','-PoolPort','20128','-LearningModulePath',$learningModulePath,'-LearningRunId',$learningRunId) $supOut $supErr;$activation.gpu_started=$true;$activation.supervisor_pid=$sup.Id;Write-Activation $activationPath $activation
  $deadline=(Get-Date).AddMinutes(8);$calPath=Join-Path $stateDir 'CALIBRATION_RESULT.json';$health=Join-Path $stateDir 'RUNTIME_HEALTH.json';$passed=$false
  while((Get-Date)-lt$deadline){Start-Sleep -Seconds 2;$sup.Refresh();if($sup.HasExited){$tail=if(Test-Path -LiteralPath $supErr){(Get-Content -LiteralPath $supErr -Tail 25)-join' | '}else{'stderr missing'};throw ('GPU supervisor exited before calibration PASS. stderr tail: '+$tail)};if((Test-Path -LiteralPath $calPath)-and(Test-Path -LiteralPath $health)){try{$cal=Read-Json $calPath;$h=Read-Json $health;if([string]$cal.status-eq'PASS'-and[string]$h.mode-match'^LIVE_'){$passed=$true;break}}catch{}}}
  if(-not$passed){throw 'GPU R065 RC16 did not pass calibrated live promotion within 8 minutes'};$activation.gpu_active=$true;$activation.status='PASS_GPU_LIVE';$activation.calibration=Read-Json $calPath;$activation.runtime_health=Read-Json $health;$activation.supervisor_stderr=$supErr;$activation.supervisor_stdout=$supOut
  Pass-MainLearningStage 'GPU_ACTIVATION' 'Start GPU supervisor, let it bootstrap, calibrate 10/25/40, and promote live only on measured control evidence' 'GPU_LIVE_PASS' 'GPU supervisor reached calibrated live state.' @{minimum_stable_productive_duty=$activation.calibration.minimum_stable_productive_duty;health_mode=$activation.runtime_health.mode;supervisor_pid=$sup.Id}

  Start-MainLearningStage 'CPU_RC6_COEXISTENCE_POST' 'Prove CPU RC6 remained alive and advancing after GPU promotion'
  $h3=Read-Json $cpuHealth;if([string]$h3.mode-ne'ACTIVE_CONTINUOUS'-or[int]$h3.loop_samples-le[int]$h2.loop_samples){throw 'CPU R063 RC6 coexistence post-proof failed'};$activation.checks.cpu_rc6_post='PASS';$activation.cpu_rc6_untouched=$true;Pass-MainLearningStage 'CPU_RC6_COEXISTENCE_POST' 'Prove CPU RC6 remained alive and advancing after GPU promotion' 'CPU_RC6_POST_PASS' 'CPU RC6 remained ACTIVE_CONTINUOUS and advanced after GPU promotion.' @{loop_before=[int]$h2.loop_samples;loop_after=[int]$h3.loop_samples;mode=[string]$h3.mode}

  Complete-MiningSniperLearningRun -ProjectRoot $Root -RunId $learningRunId -Release $Release -Outcome PASS -ReasonCode 'GPU_LIVE_AND_LEARNING_ACTIVE' -ReasonText 'GPU control-surface PASS and live promotion succeeded; CPU RC6 remained independent.' -Evidence @{activation_report=$activationPath;calibration=$calPath;health=$health;minimum_stable_productive_duty=$activation.calibration.minimum_stable_productive_duty} -ComponentOutcomes @{learning_store='PASS';duty_root_cause_fixture='PASS';cpu_rc6='PASS_UNTOUCHED';gpu_live='PASS'}|Out-Null
  $activation.completed_utc=(Get-Date).ToUniversalTime().ToString('o');$activation.learning.final_event='RUN_FINAL_PASS';Write-Activation $activationPath $activation
  Write-Host '';Write-Host 'MININGSNIPER R065 GPU RC16: PASS / GPU LIVE + LEARNING ACTIVE' -ForegroundColor Green;Write-Host ('GPU LIVE FLOOR: '+$activation.calibration.minimum_stable_productive_duty);Write-Host ('ACTIVATION REPORT: '+$activationPath);Write-Host ('LEARNING BASE: '+$learningBasePath);Write-Host ('LEARNING JOURNAL: '+$learningJournalPath)
  exit 0
}catch{
  $msg=$_.Exception.Message;$activation.status='FAIL';$activation.error=$msg;$activation.completed_utc=(Get-Date).ToUniversalTime().ToString('o');$activation.cpu_rc6_untouched=$true
  if($script:learningAvailable){
    try{
      if(-not[string]::IsNullOrWhiteSpace($script:currentLearningStage)){Write-MiningSniperLearningStep -ProjectRoot $Root -RunId $learningRunId -Release $Release -StepId $script:currentLearningStage -Outcome FAIL -Decision 'Decision-critical activation stage' -ReasonCode 'EXCEPTION' -ReasonText $msg -Evidence @{exception_type=$_.Exception.GetType().FullName;exception_message=$msg;script_stack=$_.ScriptStackTrace;position_message=$_.InvocationInfo.PositionMessage;activation_report=$activationPath;gpu_started=$activation.gpu_started;gpu_active=$activation.gpu_active;current_stage=$script:currentLearningStage}|Out-Null}
      Complete-MiningSniperLearningRun -ProjectRoot $Root -RunId $learningRunId -Release $Release -Outcome FAIL -ReasonCode 'ACTIVATION_EXCEPTION' -ReasonText $msg -Evidence @{exception_type=$_.Exception.GetType().FullName;exception_message=$msg;script_stack=$_.ScriptStackTrace;position_message=$_.InvocationInfo.PositionMessage;activation_report=$activationPath;gpu_started=$activation.gpu_started;gpu_active=$activation.gpu_active;current_stage=$script:currentLearningStage} -ComponentOutcomes @{learning_store='PASS_UNLESS_FAILURE_OCCURRED_INSIDE_LEARNING_BOOTSTRAP';cpu_rc6_untouched=$true;gpu_started=$activation.gpu_started;gpu_live=$activation.gpu_active}|Out-Null
      $activation.learning.final_event='RUN_FINAL_FAIL'
    }catch{$activation.learning.writer_failure=$_.Exception.Message}
  }else{
    try{Write-BootstrapLearningEvent (New-BootstrapEvent 'RUN_FINAL_FAIL' 'RUN' 'FAIL' 'Finalize runtime attempt' 'ACTIVATION_EXCEPTION' $msg @{activation_report=$activationPath;gpu_started=$activation.gpu_started;gpu_active=$activation.gpu_active;current_stage=$script:currentLearningStage;exception_type=$_.Exception.GetType().FullName})}catch{}
  }
  if($activation.gpu_started){try{$p=Get-Process -Id $activation.supervisor_pid -ErrorAction SilentlyContinue;if($p){Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}}catch{};try{if(Test-Path -LiteralPath (Join-Path $stateDir 'miner.pid')){$mp=[int](Get-Content -Raw -LiteralPath (Join-Path $stateDir 'miner.pid'));Stop-Process -Id $mp -Force -ErrorAction SilentlyContinue}}catch{}}
  Write-Activation $activationPath $activation;Write-Host '';Write-Host ('MININGSNIPER R065 GPU RC16: FAIL - '+$msg) -ForegroundColor Red;Write-Host 'CPU R063 RC6 WAS NOT STOPPED OR RECONFIGURED.';Write-Host ('ACTIVATION REPORT: '+$activationPath);Write-Host ('LEARNING BASE: '+$learningBasePath);Write-Host ('LEARNING JOURNAL: '+$learningJournalPath);Write-Host ('LEARNING RUN ID: '+$learningRunId);Write-Host 'Do not rerun after FAIL; return activation report + learning base.';exit 1
}

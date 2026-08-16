from pathlib import Path
import hashlib, sys

src=Path(sys.argv[1])
out=Path(sys.argv[2])
s=src.read_text(encoding='utf-8-sig')

# New release identity only; GPU/control semantics are intentionally unchanged.
s=s.replace('GPU_LANE_R065_RC16','GPU_LANE_R065_RC17')
s=s.replace('R065_RC16','R065_RC17')
s=s.replace('GPU RC16','GPU RC17')
s=s.replace('gpu-rc16','gpu-rc17')
s=s.replace('RC16','RC17')
s=s.replace('0.65.1','0.65.2')

marker="Export-ModuleMember -Function @(\n"
if marker not in s: raise SystemExit('Export-ModuleMember marker missing')
public_selftest=r'''function Test-MiningSniperLearningStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$SourceBasePath
    )

    $selfRoot = Join-Path ([IO.Path]::GetTempPath()) ('MS_LEARNING_STORE_SELFTEST_'+[guid]::NewGuid().ToString('N'))
    $selfState = Join-Path $selfRoot 'PROTECTED_STATE\Learning'
    [IO.Directory]::CreateDirectory($selfState) | Out-Null
    Copy-Item -LiteralPath $SourceBasePath -Destination (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json') -Force
    try{
        $beforeSelf = Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json') | ConvertFrom-Json
        $selfSemanticBefore = @($beforeSelf.event_log).Count
        $selfRun = 'self_'+[guid]::NewGuid().ToString('N')

        Write-MiningSniperLearningEvent -ProjectRoot $selfRoot -RunId $selfRun -Release 'LEARNING_SELFTEST' -EventType 'RUN_START' -Stage 'RUN' -Outcome 'STARTED' -Decision 'prove actual-base schema writer' -ReasonCode 'SELFTEST' -ReasonText 'schema-preserving writer selftest' | Out-Null
        Write-MiningSniperLearningEvent -ProjectRoot $selfRoot -RunId $selfRun -Release 'LEARNING_SELFTEST' -EventType 'STEP_PASS' -Stage 'A' -Outcome 'PASS' -Decision 'normal append/replay' -ReasonCode 'SELFTEST_PASS' -ReasonText 'normal event' -Evidence @{probe=42} | Out-Null
        $afterNormal = Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json') | ConvertFrom-Json
        if(@($afterNormal.event_log).Count-ne$selfSemanticBefore){throw 'Learning writer mutated semantic event_log'}
        $normalCount = @($afterNormal.runtime_event_log).Count
        Sync-MiningSniperLearningBase -ProjectRoot $selfRoot | Out-Null
        $afterReplay = Get-Content -Raw -LiteralPath (Join-Path $selfRoot 'MININGSNIPER_LEARNING_BASE.json') | ConvertFrom-Json
        if(@($afterReplay.runtime_event_log).Count-ne$normalCount){throw 'Learning replay duplicated events'}

        $paths = Get-MsLearningPaths -ProjectRoot $selfRoot
        $crashSeq = Get-MsNextRuntimeSeq -JournalPath $paths.Journal
        $crash = New-MsOrderedEvent -RunId $selfRun -RuntimeSeq $crashSeq -Release 'LEARNING_SELFTEST' -EventType 'STEP_FAIL' -Stage 'CRASH_WINDOW' -Outcome 'FAIL' -Decision 'prove WAL recovery' -ReasonCode 'SIMULATED_CRASH' -ReasonText 'journal durable, base intentionally unsynced'
        Write-MsJournalRecordDurable -JournalPath $paths.Journal -Record $crash
        $preCrash = Get-Content -Raw -LiteralPath $paths.Base | ConvertFrom-Json
        if(@($preCrash.runtime_event_log|Where-Object{$_.event_id-eq$crash.event_id}).Count-ne0){throw 'Crash-window event reached base before sync'}
        Sync-MiningSniperLearningBase -ProjectRoot $selfRoot | Out-Null
        $postCrash = Get-Content -Raw -LiteralPath $paths.Base | ConvertFrom-Json
        if(@($postCrash.runtime_event_log|Where-Object{$_.event_id-eq$crash.event_id}).Count-ne1){throw 'Crash-window replay did not recover exactly once'}

        $junk=[Text.UTF8Encoding]::new($false).GetBytes('{"event_id":"TORN')
        $jfs=[IO.FileStream]::new($paths.Journal,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read,4096,[IO.FileOptions]::WriteThrough)
        try{$jfs.Write($junk,0,$junk.Length);$jfs.Flush($true)}finally{$jfs.Dispose()}
        $tornSeq=Get-MsNextRuntimeSeq -JournalPath $paths.Journal
        $afterTorn=New-MsOrderedEvent -RunId $selfRun -RuntimeSeq $tornSeq -Release 'LEARNING_SELFTEST' -EventType 'STEP_PASS' -Stage 'TORN_TAIL_RECOVERY' -Outcome 'PASS' -Decision 'append valid event after torn tail' -ReasonCode 'SELFTEST_PASS' -ReasonText 'writer must add a separator and preserve next event'
        Write-MsJournalRecordDurable -JournalPath $paths.Journal -Record $afterTorn
        Sync-MiningSniperLearningBase -ProjectRoot $selfRoot | Out-Null
        $postTorn=Get-Content -Raw -LiteralPath $paths.Base | ConvertFrom-Json
        if(@($postTorn.runtime_event_log|Where-Object{$_.event_id-eq$afterTorn.event_id}).Count-ne1){throw 'Torn-tail recovery lost next valid event'}

        return [pscustomobject]@{
            status='PASS'
            semantic_events_preserved=$selfSemanticBefore
            normal_event_count=$normalCount
            crash_window_replay=$true
            torn_tail_recovery=$true
            writer_version=$script:MiningSniperLearningWriterVersion
        }
    }finally{
        Remove-Item -LiteralPath $selfRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

'''
s=s.replace(marker,public_selftest+marker,1)
old="    'Complete-MiningSniperLearningRun'\n)"
new="    'Complete-MiningSniperLearningRun',\n    'Test-MiningSniperLearningStore'\n)"
if old not in s: raise SystemExit('export list marker missing')
s=s.replace(old,new,1)

wb='function Write-BootstrapLearningEvent('
if wb not in s: raise SystemExit('bootstrap writer marker missing')
helper=r'''function Sync-BootstrapEventToCanonicalBase([hashtable]$Event){
  if(-not(Test-Path -LiteralPath $learningBasePath -PathType Leaf)){return $false}
  try{
    $base=Get-Content -Raw -LiteralPath $learningBasePath -Encoding UTF8|ConvertFrom-Json -AsHashtable -Depth 100
    if(-not$base.ContainsKey('runtime_event_log')){$base['runtime_event_log']=@()}
    if(-not$base.ContainsKey('runtime_revision')){$base['runtime_revision']=0}
    if(-not$base.ContainsKey('runtime_learning')){$base['runtime_learning']=[ordered]@{}}
    $seen=$false
    foreach($e in @($base['runtime_event_log'])){if($null-ne$e -and [string]$e['event_id']-eq[string]$Event['event_id']){$seen=$true;break}}
    if(-not$seen){$base['runtime_event_log']+=,$Event}
    $seq=[long]$Event['runtime_seq'];if($seq-gt[long]$base['runtime_revision']){$base['runtime_revision']=$seq}
    $base['runtime_learning']['writer_version']='bootstrap-1.1'
    $base['runtime_learning']['runtime_event_count']=@($base['runtime_event_log']).Count
    $base['runtime_learning']['last_event']=$Event
    $base['runtime_learning']['last_synced_utc']=[DateTimeOffset]::UtcNow.ToString('o')
    $base['runtime_learning']['journal']='PROTECTED_STATE\Learning\LEARNING_EVENTS.jsonl'
    $base['runtime_learning']['bootstrap_direct_base_sync']='PASS'
    $tmp=$learningBasePath+'.bootstrap.tmp';$bak=$learningBasePath+'.bak'
    $json=$base|ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($tmp,$json+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
    if(Test-Path -LiteralPath $learningBasePath){
      try{[IO.File]::Replace($tmp,$learningBasePath,$bak,$true)}catch{Copy-Item -LiteralPath $learningBasePath -Destination $bak -Force;[IO.File]::Move($tmp,$learningBasePath,$true)}
    }else{[IO.File]::Move($tmp,$learningBasePath)}
    return $true
  }catch{return $false}
}
'''
s=s.replace(wb,helper+wb,1)
old="  try{$fs.Write($bytes,0,$bytes.Length);$fs.Flush($true)}finally{$fs.Dispose()}\n  return [pscustomobject]$event"
new="  try{$fs.Write($bytes,0,$bytes.Length);$fs.Flush($true)}finally{$fs.Dispose()}\n  [void](Sync-BootstrapEventToCanonicalBase -Event $event)\n  return [pscustomobject]$event"
if old not in s: raise SystemExit('bootstrap durable-write marker missing')
s=s.replace(old,new,1)

start_marker="  $selfRoot=Join-Path $env:TEMP ('MS_LEARNING_R065_RC17_"
if start_marker not in s: raise SystemExit('old launcher selftest start missing')
start=s.index(start_marker)
end=s.index("\n  $syncReal=Sync-MiningSniperLearningBase -ProjectRoot $Root",start)
replacement=r'''  $moduleInfo=Get-Module|Where-Object{[string]$_.Path-eq[IO.Path]::GetFullPath($learningModulePath)}|Select-Object -First 1
  if($null-eq$moduleInfo){throw 'Learning module import did not produce module metadata'}
  $exported=@(Get-Command -Module $moduleInfo.Name|ForEach-Object{$_.Name})
  foreach($requiredPublic in @('Sync-MiningSniperLearningBase','Write-MiningSniperLearningEvent','Start-MiningSniperLearningRun','Write-MiningSniperLearningStep','Invoke-MiningSniperLearningStep','Complete-MiningSniperLearningRun','Test-MiningSniperLearningStore')){
    if($requiredPublic-notin$exported){throw ('MODULE-EXPORT-BOUNDARY-CLOSURE-V1 missing public command '+$requiredPublic)}
  }
  foreach($privateName in @('Get-MsLearningPaths','Get-MsNextRuntimeSeq','New-MsOrderedEvent','Write-MsJournalRecordDurable')){
    if($privateName-in$exported){throw ('MODULE-EXPORT-BOUNDARY-CLOSURE-V1 leaked private command '+$privateName)}
  }
  $activation.checks.learning_module_export_boundary='PASS'

  $syncInitial=Sync-MiningSniperLearningBase -ProjectRoot $Root
  $learningReady=$true
  $baseAfterInitial=Get-Content -Raw -LiteralPath $learningBasePath|ConvertFrom-Json
  if(@($baseAfterInitial.runtime_event_log|Where-Object{$_.run_id-eq$learningRunId}).Count-lt2){throw 'BOOTSTRAP-EVENT-IMMEDIATE-BASE-PERSISTENCE-V1 failed before selftest'}
  $activation.checks.learning_bootstrap_base_persistence='PASS'

  $selfTest=Test-MiningSniperLearningStore -ProjectRoot $Root -SourceBasePath $learningBasePath
  if([string]$selfTest.status-ne'PASS'){throw 'Learning store public selftest returned non-PASS'}
  $activation.checks.learning_schema_selftest='PASS'
  $activation.checks.learning_replay_idempotent='PASS'
  $activation.checks.learning_crash_window='PASS'
  $activation.checks.learning_torn_tail='PASS'
'''
s=s[:start]+replacement+s[end:]
s=s.replace("  $syncReal=Sync-MiningSniperLearningBase -ProjectRoot $Root\n  $learningReady=$true\n","  $syncReal=Sync-MiningSniperLearningBase -ProjectRoot $Root\n",1)
s=s.replace("    real_sync_added=[int]$syncReal.added\n","    initial_sync_added=[int]$syncInitial.added\n    real_sync_added=[int]$syncReal.added\n    module_export_boundary='PASS'\n    bootstrap_base_persistence='PASS'\n",1)

out.write_text(s,encoding='utf-8',newline='\n')
print(hashlib.sha256(out.read_bytes()).hexdigest())

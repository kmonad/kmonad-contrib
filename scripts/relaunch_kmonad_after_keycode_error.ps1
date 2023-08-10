# IMPORTANT: 
#
# 1. See below Write-Host block for how to pass parameters for the kmonad binary path and your preferred .kbd config file path
#
# 2. BE SURE -binary and -config  has " and " on either end
#
# 3. IF your kmonad executable filename doesn't match *kmonad* then go to the finally block at the end of this file
#         and update the pattern so that it will match and kill your kmonad process if the user hits Ctrl + C on this script.


# -------------========================= SCRIPT GENERAL INFORMATION =========================-------------
#
# This powershell script launches kmonad, then watches for the error message 
#       "Encountered error in KeySource: Cannot translate from windows keycode" which means the kmonad process has crashed.
#
# If it sees this, it immediately kills the existing kmonad process and then launches a new one, again watching for a crash.
#
# It also handles Ctrl + C just fine and will kill any existing kmonad processes before exiting as long as the matching pattern is 
#       correctly in the "finally" block at the end of this file.
#
# If you would like to run this from a bat file at startup, the syntax is:
# 		pwsh -command .'C:\Full\Path\To\relaunch_kmonad_after_keycode_error.ps1' -binary 'C:\Full\Path\To\Your\kmonad_binary.exe' -config 'C:\Full\Path\To\Your_Kmonad_Config.kbd'

param 
(
    [Parameter()]    
    [string]$binary,

    [Parameter()]    
    [string]$config    
)

if (([string]::IsNullOrWhiteSpace($binary)) -or
    ([string]::IsNullOrWhiteSpace($config)))
{
    Write-Host ""
    Write-Host "Either -binary or -config arguments empty."
    Write-Host ""
    Write-Host "Please call this script like this example:"
    Write-Host ".\relaunch_kmonad_after_keycode_error.ps1 -binary ""C:\Full\Path\To\Your\kmonad_binary.exe"" -config ""C:\Full\Path\To\Your_Kmonad_Config.kbd"" "
    Write-Host ""
    Write-Host "Both are REQUIRED and both MUST BE surrounded with double quotes."
    Write-Host ""

    Pause
    Exit
}

try
{
    while($true)
    {
        Write-Host "Starting new kmonad process"
    
        $blockToRun = 
        {   
            # Get variables out of parent scope and set some that we can use in this script block
            $kmonadBinaryPath = $using:binary
            $configFilePath = $using:config

            Write-Host ""
            Write-Host "Starting new kmonad process from path: "
            Write-Host "$kmonadBinaryPath"
            Write-Host ""
            Write-Host "Using config path: "
            Write-Host @($configFilePath)
            Write-Host ""
    
            $kmonadProcessInfo = New-object System.Diagnostics.ProcessStartInfo 
            $kmonadProcessInfo.CreateNoWindow = $true 
            $kmonadProcessInfo.UseShellExecute = $false 
            $kmonadProcessInfo.RedirectStandardOutput = $true 
            $kmonadProcessInfo.RedirectStandardError = $true 
            $kmonadProcessInfo.WorkingDirectory = Split-Path $kmonadBinaryPath -Parent
            $kmonadProcessInfo.FileName = $kmonadBinaryPath

            # Fix spaces, if any, in path
            $kmonadProcessInfo.Arguments = " ""$configFilePath"" "
    
            $kmonadProcess = New-Object System.Diagnostics.Process 
            $kmonadProcess.StartInfo = $kmonadProcessInfo
            
            $kmonadProcess.Start() 
            
            # This will kill the process if it sees the crash message, but this all happens internally to this job. 
            # This is necessary however, because we watch from outside this job to see if the job completes, then we launch another process.
            # This all takes place in the while loop below this ScriptBlock
            do
            {
                $currentProcessOutputLine = $kmonadProcess.StandardOutput.ReadLine()
    
                Write-Host $currentProcessOutputLine
    
                # Check for the bad thing happening and kill process if we see it
                if ($currentProcessOutputLine -clike "*Cannot translate from windows keycode*") 
                { 
                    # Error detected, killing existing kmonad process
                    $kmonadProcess.Kill()
                }
            }
            while (!$kmonadProcess.HasExited)
        }
        
        # Does not lock this thread when using Job
        $job = Start-Job -ScriptBlock $blockToRun
        
        Write-Host "Now watching for errors..."
    
        # Until the job ends, print any output, errors, or otherwise, and constantly watch for the crash message.
        do 
        {
            # Get info from the running job
            $outputLine = $job.ChildJobs[0].Output  ## read the output
            $errorLine = $job.ChildJobs[0].Error
    
            $receivedLine = Receive-Job -Job $job
            
            # Print output, error, and received strings to the console if they're not empty or default
            if ($outputLine -ne "True")
            {
                Write-Host "Output:"
                Write-Host $outputLine
            }
            
            if ($errorLine)
            {
                Write-Host "Error:"
                Write-Host $errorLine
            }
    
            if ($receivedLine)
            {
                Write-Host "Rec:"
                Write-Host $receivedLine
            }
    
            # Check for the bad thing happening and kill job if we see it
            if ($errorLine -clike "*Cannot translate from windows keycode*") 
            { 
                Write-Host "Error detected, killing existing kmonad process"
    
                $job.StopJob()
            }
        }
        while ($job.State -ne 'Completed') 
    }
}
finally
{
    # Handle Ctrl + C
    Get-Process "*kmonad*" | Stop-Process
}
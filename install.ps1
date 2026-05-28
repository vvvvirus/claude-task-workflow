$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"

if (-not (Test-Path $ClaudeDir)) {
    Write-Error "Error: $ClaudeDir not found. Is Claude Code installed?"
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing Claude Task Workflow..."

# Create directories
New-Item -ItemType Directory -Force -Path "$ClaudeDir\skills" | Out-Null
New-Item -ItemType Directory -Force -Path "$ClaudeDir\commands\task" | Out-Null

# Copy skills (-Recurse copies entire directories; -Force overwrites existing)
Copy-Item -Recurse -Force "$ScriptDir\skills\task-plan" "$ClaudeDir\skills\"
Copy-Item -Recurse -Force "$ScriptDir\skills\task-do" "$ClaudeDir\skills\"
Copy-Item -Recurse -Force "$ScriptDir\skills\task-done" "$ClaudeDir\skills\"
Copy-Item -Recurse -Force "$ScriptDir\skills\task-log" "$ClaudeDir\skills\"
Copy-Item -Recurse -Force "$ScriptDir\skills\task-list" "$ClaudeDir\skills\"

# Copy commands
Copy-Item -Force "$ScriptDir\commands\task\*.md" "$ClaudeDir\commands\task\"

Write-Host ""
Write-Host "Done. Restart Claude Code for commands to take effect."
Write-Host ""
Write-Host 'Try: /task:plan "your first task"'

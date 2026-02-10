$source = "key.pem"
$dest = "key_fixed.pem"

if (!(Test-Path $source)) {
    Write-Host "Source key not found."
    exit 1
}

# Copy content to new file to avoid locks
Copy-Item $source $dest -Force

# Get identity
$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Setting permissions on $dest for $currentIdentity"

try {
    $acl = Get-Acl $dest
    $acl.SetAccessRuleProtection($true, $false) 
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentIdentity,"FullControl","Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $dest $acl
    Write-Host "Success."
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}

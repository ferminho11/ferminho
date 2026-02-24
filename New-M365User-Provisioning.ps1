
<#
.SYNOPSIS
Automated Microsoft 365 User Provisioning Script

.DESCRIPTION
Creates a new Azure Entra ID user, assigns Microsoft 365 license,
adds user to security group, and enforces password reset.

.NOTES
Author: Enterprise IT Support Lab
#>

# -------------------------------
# Connect to Microsoft Graph
# -------------------------------
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"

# -------------------------------
# Input Variables (Modify as needed)
# -------------------------------
$DisplayName = "John Doe"
$FirstName = "John"
$LastName = "Doe"
$UserPrincipalName = "john.doe@yourtenant.onmicrosoft.com"
$MailNickname = "johndoe"
$Password = "TempP@ssw0rd123"

# License SKU (Example: ENTERPRISEPACK = M365 E3)
$LicenseSku = "ENTERPRISEPACK"

# Security Group Name
$SecurityGroupName = "Basic-User-Access"

# -------------------------------
# Create Password Profile
# -------------------------------
$PasswordProfile = @{
    Password = $Password
    ForceChangePasswordNextSignIn = $true
}

# -------------------------------
# Create New User
# -------------------------------
Write-Host "Creating new user..." -ForegroundColor Yellow

New-MgUser `
    -DisplayName $DisplayName `
    -GivenName $FirstName `
    -Surname $LastName `
    -UserPrincipalName $UserPrincipalName `
    -MailNickname $MailNickname `
    -AccountEnabled:$true `
    -PasswordProfile $PasswordProfile

Write-Host "User created successfully." -ForegroundColor Green

# -------------------------------
# Get License SKU ID
# -------------------------------
$Sku = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq $LicenseSku}

if ($Sku -eq $null) {
    Write-Host "License SKU not found. Please verify SKU name." -ForegroundColor Red
    exit
}

# -------------------------------
# Assign License
# -------------------------------
Write-Host "Assigning license..." -ForegroundColor Yellow

Set-MgUserLicense `
    -UserId $UserPrincipalName `
    -AddLicenses @{SkuId = $Sku.SkuId} `
    -RemoveLicenses @()

Write-Host "License assigned successfully." -ForegroundColor Green

# -------------------------------
# Add User to Security Group
# -------------------------------
$Group = Get-MgGroup -Filter "displayName eq '$SecurityGroupName'"

if ($Group -eq $null) {
    Write-Host "Security group not found." -ForegroundColor Red
} else {
    Write-Host "Adding user to security group..." -ForegroundColor Yellow
    
    $User = Get-MgUser -UserId $UserPrincipalName

    New-MgGroupMember `
        -GroupId $Group.Id `
        -DirectoryObjectId $User.Id

    Write-Host "User added to security group successfully." -ForegroundColor Green
}

# -------------------------------
# Completion Message
# -------------------------------
Write-Host "Provisioning process completed successfully!" -ForegroundColor Cyan

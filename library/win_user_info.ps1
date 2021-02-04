#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module Ansible.ModuleUtils.Legacy

$spec = @{
    options             = @{
        name = @{ type = "str"; default = '*' }
        sid  = @{ type = "str"; default = '*' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

# Create a new result object
$module.Result.changed = $false

$ADS_UF_PASSWD_CANT_CHANGE = 64
$ADS_UF_DONT_EXPIRE_PASSWD = 65536
$ADS_UF_PASSWD_NOTREQD = 32
$ADSI = [ADSI]"WinNT://$env:COMPUTERNAME"

Function Convert-UserFlag {
    Param ($UserFlag)
    $List = New-Object  System.Collections.ArrayList
    Switch ($UserFlag) {
        ($UserFlag -BOR 0x0001    ) { [void]$List.Add('SCRIPT') }
        ($UserFlag -BOR 0x0002    ) { [void]$List.Add('ACCOUNTDISABLE') }
        ($UserFlag -BOR 0x0008    ) { [void]$List.Add('HOMEDIR_REQUIRED') }
        ($UserFlag -BOR 0x0010    ) { [void]$List.Add('LOCKOUT') }
        ($UserFlag -BOR 0x0020    ) { [void]$List.Add('PASSWD_NOTREQD') }
        ($UserFlag -BOR 0x0040    ) { [void]$List.Add('PASSWD_CANT_CHANGE') }
        ($UserFlag -BOR 0x0080    ) { [void]$List.Add('ENCRYPTED_TEXT_PWD_ALLOWED') }
        ($UserFlag -BOR 0x0100    ) { [void]$List.Add('TEMP_DUPLICATE_ACCOUNT') }
        ($UserFlag -BOR 0x0200    ) { [void]$List.Add('NORMAL_ACCOUNT') }
        ($UserFlag -BOR 0x0800    ) { [void]$List.Add('INTERDOMAIN_TRUST_ACCOUNT') }
        ($UserFlag -BOR 0x1000    ) { [void]$List.Add('WORKSTATION_TRUST_ACCOUNT') }
        ($UserFlag -BOR 0x2000    ) { [void]$List.Add('SERVER_TRUST_ACCOUNT') }
        ($UserFlag -BOR 0x10000   ) { [void]$List.Add('DONT_EXPIRE_PASSWORD') }
        ($UserFlag -BOR 0x20000   ) { [void]$List.Add('MNS_LOGON_ACCOUNT') }
        ($UserFlag -BOR 0x40000   ) { [void]$List.Add('SMARTCARD_REQUIRED') }
        ($UserFlag -BOR 0x80000   ) { [void]$List.Add('TRUSTED_FOR_DELEGATION') }
        ($UserFlag -BOR 0x100000  ) { [void]$List.Add('NOT_DELEGATED') }
        ($UserFlag -BOR 0x200000  ) { [void]$List.Add('USE_DES_KEY_ONLY') }
        ($UserFlag -BOR 0x400000  ) { [void]$List.Add('DONT_REQ_PREAUTH') }
        ($UserFlag -BOR 0x800000  ) { [void]$List.Add('PASSWORD_EXPIRED') }
        ($UserFlag -BOR 0x1000000 ) { [void]$List.Add('TRUSTED_TO_AUTH_FOR_DELEGATION') }
        ($UserFlag -BOR 0x04000000) { [void]$List.Add('PARTIAL_SECRETS_ACCOUNT') }
    }
    $List -join ', '
}

Function Get-AnsibleLocalUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $Name = '*',
        [Parameter(Mandatory = $false)]
        [String]
        $sid = '*'
    )

    $now = Get-Date

    $ADSI.Children | Where-Object {
        $_.SchemaClassName -eq 'User' -and $_.Name -like $Name

    } | ForEach-Object -Process {
        $securityIdentifier = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $_.ObjectSid.Value, 0

        if ($securityIdentifier -like $sid) {
            $flags = $_.UserFlags.Value

            $PasswordAge = $_.PasswordAge.Value
            $maxPasswordAge = $user.MaxPasswordAge.Value
            $PasswordLastSet = $now.AddSeconds(-$PasswordAge)
            $PasswordExpiryDate = $now.AddSeconds($maxPasswordAge - $PasswordAge)

            [PSCustomObject]@{
                AccountDisabled          = $_.AccountDisabled
                #               AccountExpires           = $_.AccountExpirationDate
                BadPasswordAttempts      = $_.BadPasswordAttempts[0]
                IsAccountLocked          = $_.IsAccountLocked
                Description              = $_.Description.Value
                FullName                 = $_.FullName.Value
                Groups                   = @($_.Groups() | ForEach-Object -Process { $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null) })
                HomeDirectory            = $_.HomeDirectory.Value
                LastLogon                = If ($_.LastLogin[0] -is [DateTime]) { $_.LastLogin[0] } Else { [DateTime]::MinValue }
                LoginScript              = $_.LoginScript.Value
                MaxBadPasswords          = $_.MaxBadPasswordsAllowed[0]
                MaxPasswordAge           = [Math]::Round($_.MaxPasswordAge[0] / 86400)
                MinPasswordAge           = [Math]::Round($_.MinPasswordAge[0] / 86400)
                MinPasswordLength        = $_.MinPasswordLength[0]
                PasswordAge              = [Math]::Round($_.PasswordAge[0] / 86400)
                Name                     = $_.Name.Value
                PasswordChangeableDate   = $PasswordExpiryDate # $_.PasswordExpirationDate.Value
                PasswordExpired          = [bool]$_.PasswordExpired.Value
                PasswordLastSet          = $PasswordLastSet
                PasswordNeverExpires     = [bool]($flags -band $ADS_UF_DONT_EXPIRE_PASSWD)
                PasswordRequired         = -not [bool]($flags -band $ADS_UF_PASSWD_NOTREQD)
                Profile                  = $_.Profile.Value
                SecurityIdentifier       = [string]$securityIdentifier
                UserCannotChangePassword = [bool]($flags -band $ADS_UF_PASSWD_CANT_CHANGE)
                UserFlags                = Convert-UserFlag -UserFlag $flags
                BaseObject               = $_
            }
        }
    }
}

$AnsibleLocalUserFilters = @{}
if ($module.Params.ContainsKey('name') -and -not ($null -eq $module.Params.name) -and -not ('*' -eq $module.Params.name)) {
    $AnsibleLocalUserFilters.Name = $module.Params.name
}

if ($module.Params.ContainsKey('sid') -and -not ($null -eq $module.Params.sid) -and -not ('*' -eq $module.Params.sid)) {
    $AnsibleLocalUserFilters.Sid = $module.Params.sid
}

$localUsers = Get-AnsibleLocalUser @AnsibleLocalUserFilters

$local_user_info = @()

foreach ($user in $localUsers) {

    $local_user_info += @{
        account_disabled            = ($user.AccountDisabled | ConvertTo-Bool)
        #        account_expires             = [string]$user.AccountExpires
        account_locked              = ($user.IsAccountLocked | ConvertTo-Bool)
        description                 = [string]$user.Description
        fullname                    = [string]$user.FullName
        groups                      = $user.Groups
        home_directory              = [string]$user.HomeDirectory
        last_logon                  = [string]$user.LastLogon.tostring("u")
        login_script                = [string]$user.LoginScript
        name                        = [string]$user.Name
        password_changeable_date    = [string]$user.PasswordChangeableDate.tostring("u")
        password_expired            = ($user.PasswordExpired | ConvertTo-Bool)
        password_last_set           = [string]$user.PasswordLastSet.tostring("u")
        password_never_expires      = $user.PasswordNeverExpires
        password_required           = $user.PasswordRequired
        profile                     = $user.Profile
        sid                         = $user.SecurityIdentifier
        user_cannot_change_password = $user.UserCannotChangePassword
    }
}

$module.result.local_user_info = $local_user_info

# Return result
$module.ExitJson()

function Get-AnsibleCSharpUtils {
    param (
        [parameter(ValueFromPipeline)]
        [string]$Path
    )
    $content = get-content -path $Path
    $module_pattern = [Regex]"(?im)#AnsibleRequires -CSharpUtil (?<module>[a-z.]*)"
    $modules_matches = $module_pattern.Matches($content)
    foreach ($match in $modules_matches) {
        $match.Groups["module"].Value
    }
}

function Import-AnsibleCSharpUtils {
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$name
    )
    begin {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    process {
        $moduleName = $_
        $ModulePath = "$Here\$moduleName.cs"
        if (!(Test-Path -Path $ModulePath)) {
            $url = "https://raw.githubusercontent.com/ansible/ansible/stable-2.8/lib/ansible/module_utils/csharp/$moduleName.cs"
            $output = "$Here\$moduleName.cs"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $output)
        }
        $_csharp_utils = @(
            [System.IO.File]::ReadAllText($ModulePath)
        )
        'Ansible.ModuleUtils.AddType' | Import-AnsibleModuleUtils

        Add-CSharpType -References $_csharp_utils -IncludeDebugInfo
    }
}

function Get-AnsibleModuleUtils {
    param (
        [parameter(ValueFromPipeline)]
        [string]$Path
    )
    $content = get-content -path $Path
    $module_pattern = [Regex]"(?im)#Requires -Module (?<module>[a-z.]*)"
    $modules_matches = $module_pattern.Matches($content)
    foreach ($match in $modules_matches) {
        $match.Groups["module"].Value
    }
}

function Import-AnsibleModuleUtils {
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$name
    )
    begin {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    process {
        $moduleName = $_
        $ModulePath = "$Here\$moduleName.psm1"
        if (!(Test-Path -Path $ModulePath)) {
            $url = "https://raw.githubusercontent.com/ansible/ansible/stable-2.8/lib/ansible/module_utils/powershell/$moduleName.psm1"
            $output = "$Here\$moduleName.psm1"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $output)
        }
        if (-not (Get-Module -Name $moduleName -ErrorAction SilentlyContinue)) {
            Import-Module -Name $ModulePath
        }
    }
}
function Invoke-TestSetup {
    $ModuleUtils = Get-AnsibleCSharpUtils -Path $ansibleModulePath
    if ($ModuleUtils) {
        $ModuleUtils | Import-AnsibleCSharpUtils
    }

    $ModuleUtils = Get-AnsibleModuleUtils -Path $ansibleModulePath
    if ($ModuleUtils ) {
        $ModuleUtils | Import-AnsibleModuleUtils
    }
}
function Invoke-TestCleanup {
    $ModuleUtils = Get-AnsibleModuleUtils -Path $ansibleModulePath
    if ($ModuleUtils) {
        foreach ($module in $ModuleUtils) {
            if (Get-Module -Name $moduleName -ErrorAction SilentlyContinue) {
                Remove-Module -Name $module
            }
        }
    }
}

function Update-Pester {
    try {
        If (Get-Module -Name Pester) {
            $PesterVersion = [version](get-Module -Name Pester -ErrorAction SilentlyContinue).Version
        } else {
            $PesterVersion = [version](get-InstalledModule -Name Pester -ErrorAction SilentlyContinue).Version
        }
        $DoPesterUpdate = ($PesterVersion.Major -le 3)
    }
    catch {
        $DoPesterUpdate = $true
    }
    finally {
        if ($DoPesterUpdate) {
            Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
            $PesterVersion = [version](get-InstalledModule -Name Pester -ErrorAction SilentlyContinue).Version
        }
        $CurrentPesterVersion = [version](get-module -name Pester).Version
        if ($CurrentPesterVersion.Major -lt $PesterVersion.Major) {
            Remove-Module -name Pester -ErrorAction SilentlyContinue
            Import-Module -Name Pester -RequiredVersion $PesterVersion -ErrorAction SilentlyContinue
        }
        }
}


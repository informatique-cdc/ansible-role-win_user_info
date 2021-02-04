# Set $ErrorActionPreference to what's set during Ansible execution
$ErrorActionPreference = "Stop"

#Get Current Directory
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

.$(Join-Path -Path $Here -ChildPath 'test_utils.ps1')

# Update Pester if needed
Update-Pester

#Get Function Name
$moduleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

#Resolve Path to Module path
$ansibleModulePath = "$Here\..\..\library\$moduleName.ps1"

Invoke-TestSetup

Function Invoke-AnsibleModule {
    [CmdletBinding()]
    Param(
        [hashtable]$params
    )

    begin {
        $global:complex_args = @{
            "_ansible_check_mode" = $false
            "_ansible_diff"       = $true
        } + $params
    }
    Process {
        . $ansibleModulePath
        return $module.result
    }
}

try {
    Describe 'win_user_info' -Tag 'Get' {

        Context 'users are present installed' {

            # BeforeAll {
            # }

            It 'Should return administrator only' {

                $params = @{
                    sid = '*-500'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $false
            }

            It 'Should return all users' {

                $params = @{
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $false
            }


            It 'Should return administrator only' {

                $params = @{
                    name = 'admi*'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $false
            }

            It 'Should return empty result' {

                $params = @{
                    name = 'test*'
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -Be $false
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}

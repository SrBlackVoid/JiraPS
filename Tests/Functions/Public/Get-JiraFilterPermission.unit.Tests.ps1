#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Get-JiraFilterPermission" -Tag 'Unit' {
    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        Initialize-TestEnvironment
        $script:moduleToTest = Resolve-ModuleSource
        Import-Module $script:moduleToTest -Force -ErrorAction Stop
        # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

        #region Definitions
        $script:jiraServer = "https://jira.example.com"

        $script:sampleResponse = @"
{
  "id": 10000,
  "type": "global"
}
"@
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraConfigServer'
            $jiraServer
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraFilter' 'Id'
            foreach ($_id in $Id) {
                [PSCustomObject]@{
                    PSTypeName = 'JiraPS.Filter'
                    ID         = $_id
                    RestUrl    = "$jiraServer/rest/api/2/filter/$_id"
                }
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission" } {
            Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $sampleResponse
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    Describe "Signature" {
        Context "Parameter Types" {
            # TODO: Add parameter type validation tests
        }

        Context "Mandatory Parameters" {}

        Context "Default Values" {}
    }

    Describe "Behavior" {
        Context "Behavior testing" {
            It "Retrieves the permissions of a Filter by Object" {
                { Get-TestJiraFilter -Id 23456 -JiraServer $jiraServer | Get-JiraFilterPermission } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/filter/23456/permission'
                }
            }

            It "Retrieves the permissions of a Filter by Id" {
                { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/filter/23456/permission'
                }
            }
        }

        Context "Input testing" {
            It "finds the filter by Id" {
                { Get-JiraFilterPermission -Id 23456 } | Should -Not -Throw

                Should -Invoke Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1
            }

            It "does not accept negative Ids" {
                { Get-JiraFilterPermission -Id -1 } | Should -Throw -ExpectedMessage "*'Id'*"
            }

            It "can process multiple Ids" {
                { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

                Should -Invoke Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
            }

            It "allows for the filter to be passed over the pipeline" {
                { Get-TestJiraFilter -Id 23456 -JiraServer $jiraServer | Get-JiraFilterPermission } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
            }

            It "can only process one Filter objects" {
                $filter = @()
                $filter += Get-TestJiraFilter -Id 23456 -JiraServer $jiraServer
                $filter += Get-TestJiraFilter -Id 23456 -JiraServer $jiraServer

                { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
            }

            It "resolves positional parameters" {
                { Get-JiraFilterPermission 23456 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1

                $filter = Get-TestJiraFilter -Id 23456 -JiraServer $jiraServer
                { Get-JiraFilterPermission $filter } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
            }
        }
    }

    Describe "Input Validation" {
        Context "Type Validation - Positive Cases" {}

        Context "Type Validation - Negative Cases" {}
    }
}

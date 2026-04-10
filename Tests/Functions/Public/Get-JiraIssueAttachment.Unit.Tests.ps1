#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Get-JiraIssueAttachment" -Tag 'Unit' {
    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        Initialize-TestEnvironment
        $script:moduleToTest = Resolve-ModuleSource
        Import-Module $script:moduleToTest -Force -ErrorAction Stop
        # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

        #region Definitions
        $script:jiraServer = 'http://jiraserver.example.com'
        $script:issueID = 41701
        $script:issueKey = 'IT-3676'

        $script:attachments = @"
[
    {
        "self": "$jiraServer/rest/api/2/attachment/10013",
        "id": "10013",
        "filename": "foo.pdf",
        "author": {
            "self": "$jiraServer/rest/api/2/user?username=admin",
            "name": "admin",
            "key": "admin",
            "accountId": "000000:000000-0000-0000-0000-ab899c878d00",
            "emailAddress": "admin@example.com",
            "avatarUrls": { },
            "displayName": "Admin",
            "active": true,
            "timeZone": "Europe/Berlin"
        },
        "created": "2017-10-16T10:06:29.399+0200",
        "size": 60444,
        "mimeType": "application/pdf",
        "content": "$jiraServer/secure/attachment/10013/foo.pdf"
    },
    {
        "self": "$jiraServer/rest/api/2/attachment/10010",
        "id": "10010",
        "filename": "bar.pdf",
        "author": {
            "self": "$jiraServer/rest/api/2/user?username=admin",
            "name": "admin",
            "key": "admin",
            "accountId": "000000:000000-0000-0000-0000-ab899c878d00",
            "emailAddress": "admin@example.com",
            "avatarUrls": { },
            "displayName": "Admin",
            "active": true,
            "timeZone": "Europe/Berlin"
        },
        "created": "2017-10-16T09:06:48.070+0200",
        "size": 438098,
        "mimeType": "'application/pdf'",
        "content": "$jiraServer/secure/attachment/10010/bar.pdf"
    }
]
"@
        #endregion Definitions

        #region Mocks
        Mock Get-JiraIssue -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraIssue'
            [PSCustomObject]@{
                PSTypeName = 'JiraPS.Issue'
                ID         = $issueID
                Key        = $issueKey
                RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                attachment = (ConvertFrom-Json -InputObject $attachments)
            }
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    Describe "Input Validation" {
        BeforeAll {
            $script:issueObject = [PSCustomObject]@{
                PSTypeName = 'JiraPS.Issue'
                ID         = $issueID
                Key        = $issueKey
                RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                attachment = (ConvertFrom-Json -InputObject $attachments)
            }
        }

        It 'only accepts String or JiraPS.Issue as input' {
            { Get-JiraIssueAttachment -Issue (Get-Date) } | Should -Throw -ExpectedMessage "*Invalid Type*"
            { Get-JiraIssueAttachment -Issue (Get-ChildItem) } | Should -Throw -ExpectedMessage "*Invalid Type*"
            { Get-JiraIssueAttachment -Issue @('foo', 'bar') } | Should -Not -Throw
            { Get-JiraIssueAttachment -Issue (Get-TestJiraIssue -JiraServer $jiraServer -ID $issueID) } | Should -Not -Throw
        }

        It 'takes the issue input over the pipeline' {
            { $issueObject | Get-JiraIssueAttachment } | Should -Not -Throw
            { $issueKey | Get-JiraIssueAttachment } | Should -Not -Throw
        }
    }

    Describe "Signature" {
        Context "Parameter Types" {
            # TODO: Add parameter type validation tests
        }

        Context "Mandatory Parameters" {}

        Context "Default Values" {}
    }

    Describe "Behavior" {
        BeforeAll {
            $script:issueObject = [PSCustomObject]@{
                PSTypeName = 'JiraPS.Issue'
                ID         = $issueID
                Key        = $issueKey
                RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                attachment = (ConvertFrom-Json -InputObject $attachments)
            }
        }

        It 'converts the attachments to objects' {
            Mock ConvertTo-JiraAttachment -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraAttachment'
                $InputObject
            }
            $issueObject | Get-JiraIssueAttachment
            Get-JiraIssueAttachment -Issue $issueKey
            Should -Invoke ConvertTo-JiraAttachment -ModuleName JiraPS -Exactly 2
        }

        It 'filters the result by FileName' {
            @($issueObject | Get-JiraIssueAttachment) | Should -HaveCount 2
            @($issueObject | Get-JiraIssueAttachment -FileName 'foo.pdf') | Should -HaveCount 1
        }
    }

    Describe "Input Validation" {
        Context "Type Validation - Positive Cases" {}

        Context "Type Validation - Negative Cases" {}
    }
}

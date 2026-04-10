Current State

Overall Goal

Migrate all 62 public function test files in Tests/Functions/Public/ off the InModuleScope JiraPS { } outer wrapper (issue #567), which causes incorrect behavior in Pester v5. The approach: flatten the Describe block, initialize the module in
BeforeAll, add -ModuleName JiraPS to all Mock/Should -Invoke calls, use PSTypeName syntax for typed objects, and use centralized Get-TestJira* helpers for pipeline-source calls.

Completed (4 commits on copilot/InModuleScope-Fixes)

┌───────────┬─────────────────────────────────────────────────────────────────────────┐
│ Commit    │ Content                                                                 │
├───────────┼─────────────────────────────────────────────────────────────────────────┤
│ 7a1c90a   │ Phase 1: TestTools.ps1 — centralized Get-TestJira* factory helpers      │
├───────────┼─────────────────────────────────────────────────────────────────────────┤
│ 7a25592   │ Batch 1: 7 Add-Jira* files + ConvertTo-* scope narrowing                │
├───────────┼─────────────────────────────────────────────────────────────────────────┤
│ 144391c   │ Batch 2: 11 Get-JiraIssue* files                                        │
├───────────┼─────────────────────────────────────────────────────────────────────────┤
│ 360f305   │ Batch 3: 14 Get-Jira* (non-Issue) files + ConvertTo-* scope narrowing   │
└───────────┴─────────────────────────────────────────────────────────────────────────┘

39 of 62 files migrated. Remove-JiraSession was already migrated before this work began.

Key Technical Decisions

 1. No BeforeDiscovery — module init goes directly in the top-level Describe's BeforeAll
 2. -ModuleName JiraPS required on every Mock and Should -Invoke once the outer scope is removed
 3. PSTypeName syntax replaces $obj.PSObject.TypeNames.Insert(0, 'JiraPS.X') — cleaner and works outside module scope
 4. Get-TestJira* helpers in TestTools.ps1 replace pipeline-source calls to real cmdlets in test bodies (e.g., Get-TestJiraIssue instead of Get-JiraIssue piped into the function under test)
 5. ConvertTo- mocks scoped to It blocks* when only one test asserts them; removed entirely when no Should -Invoke exists; kept at BeforeAll level only when 3+ tests depend on them
 6. Inline InModuleScope inside It blocks (e.g., Get-JiraConfigServer setting $script:JiraServerUrl) is legitimate and stays

Remaining Tasks (in order)

Batch 4 — Remove-Jira* (11 files, Remove-JiraSession already done) Apply standard migration pattern. Key per-file issues (from batch4-analysis.txt):

 - Remove-JiraFilter, Remove-JiraFilterPermission: test-body calls → Get-TestJiraFilter/Get-TestJiraFilterPermission; PSTypeName fixes
 - Remove-JiraGroup, Remove-JiraGroupMember: test-body calls → Get-TestJiraGroup/Get-TestJiraUser; PSTypeName + -ModuleName fixes
 - Remove-JiraIssue, Remove-JiraIssueAttachment, Remove-JiraIssueWatcher: test-body → Get-TestJiraIssue; remove Resolve-JiraIssueObject mock (safe — real function short-circuits on typed input)
 - Remove-JiraIssueLink: PSTypeName fixes; no Get-TestJiraIssueLink helper exists — may need to add one to TestTools.ps1
 - Remove-JiraRemoteLink: PSTypeName fixes; fix wrong TypeName on Get-JiraRemoteLink mock; remove Resolve-JiraIssueObject
 - Remove-JiraUser, Remove-JiraVersion: PSTypeName fixes; test-body → Get-TestJiraUser/Get-TestJiraVersion

Batch 5 — Set-Jira* + Set-JiraConfigServer (6 files) Standard migration. Set-JiraIssue and Set-JiraVersion likely complex.

Batch 6 — New-Jira* + Find-JiraFilter + Format-Jira + Resolve-JiraError (9 files) Standard migration. New-JiraIssue will be the most complex (large body construction, reporter field).

Batch 7 — Invoke-JiraIssueTransition and Move-JiraVersion (2 files, ON HOLD) User wants to review these personally before migration.

Batch 8 — Invoke-JiraMethod (1 file, complex) Special case: uses a $assertMockCalledSplat hashtable for ~20 Should -Invoke calls — -ModuleName JiraPS must be added to that hashtable, not inline.

Final — Update .template.ps1 Update Tests/Functions/Public/.template.ps1 to reflect the new structure (no outer InModuleScope, BeforeAll with module init, Get-TestJira* usage).

Risks / Open Questions

 - Remove-JiraIssueLink: No Get-TestJiraIssueLink helper exists yet; need to confirm what properties the test needs before creating it
 - Invoke-JiraIssueTransition / Move-JiraVersion: On hold — user reviewing personally; may have unique patterns
 - JiraPS.build.ps1 has a local change (test path set to Get-Jira*) that should be updated to Remove-Jira* before Batch 4 testing, but should not be committed

Describe 'SchunkOps module' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..\module\SchunkOps\SchunkOps.psd1'
        $manifest = Test-ModuleManifest -Path $modulePath
    }

    It 'has valid manifest metadata' {
        $manifest.Name | Should -Be 'SchunkOps'
        $manifest.Version.ToString() | Should -Be '1.1.0'
        $manifest.Author | Should -Be 'David Maksim Schunk'
    }

    It 'imports without error' {
        { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'exports exactly the declared public functions' {
        Import-Module $modulePath -Force
        $actual = @(Get-Command -Module SchunkOps -CommandType Function).Name | Sort-Object
        $expected = @($manifest.ExportedFunctions.Keys) | Sort-Object

        Compare-Object -ReferenceObject $expected -DifferenceObject $actual | Should -BeNullOrEmpty
        $actual.Count | Should -Be 20
    }

    It 'provides synopsis help and David Schunk attribution for every public function' {
        Import-Module $modulePath -Force

        foreach ($command in Get-Command -Module SchunkOps -CommandType Function) {
            $help = Get-Help $command.Name -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            ($help.alertSet.alert.Text -join ' ') | Should -Match 'David Maksim Schunk'
        }
    }

    It 'honors WhatIf before creating an incident bundle' {
        Import-Module $modulePath -Force
        $target = Join-Path $TestDrive 'whatif-bundle'

        New-SchunkIncidentBundle -OutputPath $target -WhatIf

        Test-Path -LiteralPath $target | Should -BeFalse
    }

    It 'rejects an invalid disk pressure threshold relationship' {
        Import-Module $modulePath -Force
        { Get-SchunkDiskPressure -WarningFreePercent 5 -CriticalFreePercent 10 } | Should -Throw
    }

    It 'identifies changed, unchanged, added, and removed collectors' {
        Import-Module $modulePath -Force
        $referencePath = Join-Path $TestDrive 'reference'
        $differencePath = Join-Path $TestDrive 'difference'
        $null = New-Item -ItemType Directory -Path $referencePath, $differencePath

        $reference = @{
            BundleId = 'reference-bundle'
            Collectors = @(
                @{ Name = 'health'; Status = 'Success'; Sha256 = 'AAA'; RecordCount = 1 }
                @{ Name = 'ports'; Status = 'Success'; Sha256 = 'BBB'; RecordCount = 2 }
                @{ Name = 'removed'; Status = 'Success'; Sha256 = 'CCC'; RecordCount = 3 }
            )
        }
        $difference = @{
            BundleId = 'difference-bundle'
            Collectors = @(
                @{ Name = 'health'; Status = 'Success'; Sha256 = 'AAA'; RecordCount = 1 }
                @{ Name = 'ports'; Status = 'Success'; Sha256 = 'CHANGED'; RecordCount = 4 }
                @{ Name = 'added'; Status = 'Success'; Sha256 = 'DDD'; RecordCount = 5 }
            )
        }

        $reference | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $referencePath 'manifest.json')
        $difference | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $differencePath 'manifest.json')
        $result = Compare-SchunkIncidentBundle -ReferencePath $referencePath -DifferencePath $differencePath

        ($result | Where-Object Collector -eq 'health').Change | Should -Be 'Unchanged'
        ($result | Where-Object Collector -eq 'ports').Change | Should -Be 'Changed'
        ($result | Where-Object Collector -eq 'added').Change | Should -Be 'Added'
        ($result | Where-Object Collector -eq 'removed').Change | Should -Be 'Removed'
    }
}

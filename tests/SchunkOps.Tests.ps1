$modulePath = Join-Path $PSScriptRoot '..\module\SchunkOps\SchunkOps.psd1'
$manifest = Test-ModuleManifest -Path $modulePath

Describe 'SchunkOps module' {
    It 'has valid manifest metadata' {
        $manifest.Name | Should -Be 'SchunkOps'
        $manifest.Version.ToString() | Should -Be '1.0.0'
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
        $actual.Count | Should -Be 10
    }

    It 'provides synopsis help and David Schunk attribution for every public function' {
        Import-Module $modulePath -Force

        foreach ($command in Get-Command -Module SchunkOps -CommandType Function) {
            $help = Get-Help $command.Name -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            ($help.alertSet.alert.Text -join ' ') | Should -Match 'David Maksim Schunk'
        }
    }
}

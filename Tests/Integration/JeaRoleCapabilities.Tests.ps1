Using Module ..\..\JeaDsc.psd1

Describe "Integration testing JeaRoleCapabilities" -Tag Integration {

    BeforeAll {
        $ModulePath = Resolve-Path -Path $PSScriptRoot\..\..\..\
        $OldPsModulePath = $Env:PSModulePath
        $Env:PSModulePath += ";$ModulePath"
        [Environment]::SetEnvironmentVariable('PSModulePath',$Env:PSModulePath,[EnvironmentVariableTarget]::Machine)
        $Env:PSModulePath += ";TestDrive:\"
    }

    AfterAll {
        [Environment]::SetEnvironmentVariable('PSModulePath',$OldPsModulePath,[EnvironmentVariableTarget]::Machine)
    }

    BeforeEach {
        $class = [JeaRoleCapabilities]::New()
        $class.Path = 'TestDrive:\ModuleFolder\RoleCapabilities\ExampleRole.psrc'
    }


    Context "Testing Get method when Ensure is Present" {

        It "Should return an object of JeaRoleCapabilities type" {

            $null = New-Item -Path $class.Path -Force
            $null = New-PSRoleCapabilityFile -Path $class.Path -VisibleCmdlets 'Get-Command'

            $Result = $class.Get()

            $Result.GetType().Name | Should -Be 'JeaRoleCapabilities'
        }

        It "Should remove Copyright, GUID, Author and CompanyName from the object after importing the psrc" {

            $null = New-Item -Path $class.Path -Force
            $null = New-PSRoleCapabilityFile -Path $class.Path -VisibleCmdlets 'Get-Command'

            $Result = $class.Get()

            $Result.PSObject.Properties | Should -Not -Contain 'Copyright'
            $Result.PSObject.Properties | Should -Not -Contain 'GUID'
            $Result.PSObject.Properties | Should -Not -Contain 'Author'
            $Result.PSObject.Properties | Should -Not -Contain 'CompanyName'
        }

        It "Should return an object with property Ensure set to Present" {

            $null = New-Item -Path $class.Path -Force
            $null = New-PSRoleCapabilityFile -Path $class.Path -VisibleCmdlets 'Get-Command'

            $Result = $class.Get()

            $Result.Ensure | Should -Be 'Present'
        }

        It "Should populate returned properties from VisibleCmdlets in psrc file" {

            $null = New-Item -Path $class.Path -Force
            $null = New-PSRoleCapabilityFile -Path $class.Path -VisibleCmdlets 'Get-Command'

            $Result = $class.Get()

            $Result.VisibleCmdlets | Should -Be 'Get-Command'
        }

    }

    Context "Testing Get method when Ensure is Absent" {

        It "Should return an object of JeaRoleCapabilities type" {

            $Result = $class.Get()

            $Result.GetType().Name | Should -Be 'JeaRoleCapabilities'
        }

        It "Should return an object with property Ensure set to Present" {

            $Result = $class.Get()

            $Result.Ensure | Should -Be 'Absent'
        }
    }

    Context "Testing Set method when Ensure is Present" {

        It "Should create a new RoleCapbailities folder and populate with a psrc file with 1 visible function" {
            $class.VisibleFunctions = 'Get-Service'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'Get-Service'
        }

        It "Should create a new psrc with 1 visible function and all Get cmdlets visible" {
            $class.VisibleCmdlets = 'Get-*'
            $class.VisibleFunctions = 'New-Example'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'New-Example'
            $result.VisibleCmdlets | Should -Be 'Get-*'
        }

        It "Should create a new psrc from an array of strings with 1 visible function and all cmdlets in DnsServer module and Restart-Service visible" {
            $class.VisibleCmdlets = 'DnsServer\*', "@{'Name' = 'Restart-Service';'Parameters' = @{'Name' = 'Name';'ValidateSet' = 'Dns' } }"
            $class.VisibleFunctions = 'New-Example'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'New-Example'
            $result.VisibleCmdlets[0] | Should -Be 'DnsServer\*'
            $result.VisibleCmdlets[1] | Should -BeOfType [Hashtable]
            $result.VisibleCmdlets[1].Name | Should -Be 'Restart-Service'
            $result.VisibleCmdlets[1].Parameters.Name | Should -Be 'Name'
            $result.VisibleCmdlets[1].Parameters.ValidateSet | Should -Be 'Dns'
        }

        It "Should create a new psrc from a single string with 1 visible function and all cmdlets in DnsServer module and Restart-Service visible" {
            $class.VisibleCmdlets = 'DnsServer\*, @{"Name" = "Restart-Service";"Parameters" = @{"Name" = "Name";"ValidateSet" = "Dns" } }'
            $class.VisibleFunctions = 'New-Example'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'New-Example'
            $result.VisibleCmdlets[0] | Should -Be 'DnsServer\*'
            $result.VisibleCmdlets[1] | Should -BeOfType [Hashtable]
            $result.VisibleCmdlets[1].Name | Should -Be 'Restart-Service'
            $result.VisibleCmdlets[1].Parameters.Name | Should -Be 'Name'
            $result.VisibleCmdlets[1].Parameters.ValidateSet | Should -Be 'Dns'
        }

        It "Should create a psrc with a function definition and a visible function for that custom function" {
            $class.FunctionDefinitions = "@{Name = 'Get-ExampleFunction'; ScriptBlock = {Get-Command} }"
            $class.VisibleFunctions = 'Get-ExampleFunction'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'Get-ExampleFunction'
            $result.FunctionDefinitions.Name | Should -Be 'Get-ExampleFunction'
            $result.FunctionDefinitions.Scriptblock | Should -Be '{Get-Command}'
            $result.FunctionDefinitions.Scriptblock | Should -BeOfType [ScriptBlock]
        }

        It "Should create a psrc with 2 function definitions and 2 visible function for those custom function" {
            $class.FunctionDefinitions = "@{Name = 'Get-ExampleFunction'; ScriptBlock = {Get-Command} }","@{Name = 'Get-OtherExample'; ScriptBlock = {Get-Command} }"
            $class.VisibleFunctions = 'Get-ExampleFunction','Get-OtherExample'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'Get-ExampleFunction','Get-OtherExample'
            $result.FunctionDefinitions[0].Name | Should -Be 'Get-ExampleFunction'
            $result.FunctionDefinitions[0].Scriptblock | Should -Be '{Get-Command}'
            $result.FunctionDefinitions[0].Scriptblock | Should -BeOfType [ScriptBlock]
            $result.FunctionDefinitions[1].Name | Should -Be 'Get-OtherExample'
            $result.FunctionDefinitions[1].Scriptblock | Should -Be '{Get-Command}'
            $result.FunctionDefinitions[1].Scriptblock | Should -BeOfType [ScriptBlock]
        }
    }

    Context "Testing Set method when Ensure is Absent" {

        It "Should remove the role capabilities file" {
            New-Item -Path 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc' -Force

            $class.Ensure = [Ensure]::Absent
            $class.Path = 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc'
            $class.Set()

            Test-Path -Path 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc' | Should -Be $false

        }
    }

    Context "Testing Applying BasicVisibleCmdlets Configuration File" {

        It "Should apply the example BasicVisibleCmdlets configuration without throwing" {
            $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath 'TestConfigurations\BasicVisibleCmdlets.config.ps1'
            . $ConfigFile

            &winrm quickconfig -quiet -force

            $MofOutputFolder = 'TestDrive:\Configurations\BasicVisibleCmdlets'
            $PsrcPath = Join-Path (Get-Item TestDrive:\).FullName -ChildPath 'BasicVisibleCmdlets\RoleCapabilities\BasicVisibleCmdlets.psrc'
            &BasicVisibleCmdlets -OutputPath $MofOutputFolder -Path $PsrcPath
            { Start-DscConfiguration -Path $MofOutputFolder -Wait -Force } | Should -Not -Throw
        }

        It "Should be able to call Get-DscConfiguration without throwing" {
            { Get-DscConfiguration -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should have created the psrc file and set the VisibleCmdlets to Get-Service" {
            Test-Path -Path 'TestDrive:\BasicVisibleCmdlets\RoleCapabilities\BasicVisibleCmdlets.psrc' | Should -Be $true

            $results = Import-PowerShellDataFile -Path 'TestDrive:\BasicVisibleCmdlets\RoleCapabilities\BasicVisibleCmdlets.psrc'

            $results.VisibleCmdlets | Should -Be 'Get-Service'
        }
    }

    Context "Testing Applying WildcardVisibleCmdlets Configuration File" {

    }

    Context "Testing Applying FunctionDefinitions Configuration File" {

    }

    Context "Testing Applying FailingFunctionDefinitions Configuration File" {

    }
}

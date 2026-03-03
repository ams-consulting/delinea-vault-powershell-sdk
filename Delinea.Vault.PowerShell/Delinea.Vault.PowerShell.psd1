###########################################################################################
# Delinea Vault PowerShell module manifest
#
# Author   : Fabrice Viguier
# Contact  : support AT ams-consulting.uk
# Release  : 19/05/2025
# License  : MIT License
#
# Copyright (c) 2025 AMS Consulting.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###########################################################################################

@{
    Author = 'Fabrice Viguier'
    CompanyName	= 'AMS Consulting'
    Copyright = 'MIT License Copyright (c) 2025 AMS Consulting Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to dealin the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
    Description = 'This unofficial PowerShell module is to be used with Delinea Vault.'
    GUID = '325f94ca-6660-a42b-210d-27a309d34cd5'
    RootModule = 'Delinea.Vault.PowerShell.psm1'
    ModuleVersion = '0.3.0112'
    NestedModules = @(
        # Loading Core Cmdlets
        '.\Lib\Connect-DlnVault.ps1',
        '.\Lib\Disconnect-DlnVault.ps1',
        # Loading Access Cmdlets
        '.\Lib\Get-DlnUser.ps1',
        '.\Lib\Get-DlnGroup.ps1',
        '.\Lib\Get-DlnRole.ps1',
        # Loading Secret Cmdlets
        '.\Lib\Get-DlnFolder.ps1',
        '.\Lib\Get-DlnSecret.ps1',
        '.\Lib\New-DlnFolder.ps1',
        '.\Lib\New-DlnSecret.ps1',
        '.\Lib\Remove-DlnFolder.ps1',
        '.\Lib\Set-DlnAssociatedSecret.ps1',
        # Loading Settings/General Cmdlets
        '.\Lib\Get-DlnSecretPolicy.ps1',
        '.\Lib\Get-DlnSecretTemplate.ps1',
        '.\Lib\Get-DlnSite.ps1'
    )
    PowerShellVersion = '5.1'
    RequiredAssemblies = @()
}
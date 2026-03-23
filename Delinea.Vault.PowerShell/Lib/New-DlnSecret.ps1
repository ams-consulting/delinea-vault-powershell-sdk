###########################################################################################
# Delinea Vault PowerShell module
#
# Author   : Fabrice Viguier
# Contact  : support AT ams-consulting.uk
# Release  : 27/05/2025
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

<#
.SYNOPSIS
Create a new secret.

.DESCRIPTION
This Cmdlet create a new secret.

.PARAMETER Name
Specify the User by its username.

.INPUTS
None

.OUTPUTS
[Object]DlnSecret

.EXAMPLE
PS C:\> New-DlnSecret 
Create a new secret
#>
function New-DlnSecret {
	param (
		[Parameter(Mandatory, HelpMessage = "The name to display for the secret.")]
		[String]$Name,

   		[Parameter(Mandatory, HelpMessage = "The id of the secret template that defines the fields and properties of the secret.")]
		[String]$SecretTemplateId,

        [Parameter(Mandatory, HelpMessage = "An object listing the secret fields defined in the secret template representing slugnames and field values.")]
		[Object]$Fields,

		[Parameter(HelpMessage = "If the secret is contained in a folder, the id of the containing folder. Set to null or -1 for secrets that are in the root folder.")]
		[String]$FolderId,

        [Parameter(HelpMessage = "The id of the secret policy that controls the security and other settings of the secret. Set to null to not assign a secret policy.")]
		[String]$SecretPolicyId,

        [Parameter(HelpMessage = "The id of the distributed engine site that is used by this secret for operations such as password changing.")]
		[String]$SiteId,

        [Parameter(HelpMessage = "Secret used to change the current secret's password.")]
		[String]$PrivilegedAccountSecretId,

        [Parameter(HelpMessage = "Secrets used in password changers commands and scripts.")]
		[String[]]$ResetSecretIds,

        [Parameter(HelpMessage = "Whether the secret inherits permissions from the containing folder.")]
		[Switch]$EnableInheritPermissions,

        [Parameter(HelpMessage = "Whether the secret policy is inherited from the containing folder.")]
		[Switch]$EnableInheritSecretPolicy,

		[Parameter(HelpMessage = "Whether to generate an SSH private key passphrase. Only applicable when the Secret template has a password changer with the Private Key Passphrase field mapped. If it is not mapped, this setting is ignored.")]
		[Switch]$GeneratePassphrase,

        [Parameter(HelpMessage = "Whether to generate an SSH private key.")]
		[Switch]$GenerateSshKeys,
        
		[Parameter(HelpMessage = "Whether the secret's password is automatically rotated on a schedule.")]
		[Switch]$AutoChangeEnabled
	)

    try {
        # Test current connection to the Delinea Vault
        if ($Global:VaultConnection -eq [Void]$null) {
            # Inform connection does not exists and suggest to initiate one
            Write-Warning ("No connection could be found with the Delinea Secret Server Vault. Use Connect-DlnVault Cmdlet to create a valid connection.")
            Break
        } else {
            if ($Global:VaultConnection.expires_at -lt [DateTime]::Now) {
                # Refresh expired session token
                Connect-DlnVault -RefreshToken
            }
        }

        # First step is to get a Stub Secret from Secret Template
        if([String]::IsNullOrEmpty($FolderId)) {
            # FolderId not present - Note that FolderId must be present if Global Settings that requires no Secrets to be created at root folder level is enabled
            $StubSecret = Get-DlnSecretStub -SecretTemplateId $SecretTemplateId
        } else {
            # FolderId is present
            $StubSecret = Get-DlnSecretStub -SecretTemplateId $SecretTemplateId -FolderId $FolderId
        }
        # Fail here if unable to generate Stub Secret
        if($StubSecret -eq [Void]$null) {
            Throw ("Unable to generate Stub Secret using SecretTemplateId '{0}'." -f $SecretTemplateId)
        }

        # Setup values for API request
        $Uri = ("{0}/api/v1/secrets" -f $VaultConnection.Url)
        $ContentType = "application/json"
        $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

        # Set Parameters using stub secret
        # Add mandatory parameters
        $StubSecret.name = $Name
        #$StubSecret.secretTemplateId = $SecretTemplateId
        # Add Items itemValue based on slug from Fields
        $StubSecret.items | ForEach-Object {
            # Update itemVaule only if passed as a Field
            if(-not [String]::IsNullOrEmpty($Fields.($_.slug))) {
                $_.itemValue = $Fields.($_.slug)
            }
        }
        # Add optional parameters
        if(-not [String]::IsNullOrEmpty($FolderId)) {
            $StubSecret.folderId = [Int32]$FolderId
        }
        if(-not [String]::IsNullOrEmpty($SecretPolicyId)) {
            $StubSecret.secretPolicyId = [Int32]$SecretPolicyId
        }
        if(-not [String]::IsNullOrEmpty($SiteId)) {
            $StubSecret.siteId = [Int32]$SiteId
        }
        if(-not [String]::IsNullOrEmpty($PrivilegedAccountSecretId)) {
            $StubSecret.privilegedAccountSecretId = [Int32]$PrivilegedAccountSecretId
        }
        if(-not [String]::IsNullOrEmpty($ResetSecretIds)) {
            $StubSecret.resetSecretIds = [Int32[]]$ResetSecretIds
        }
        # Add boolean values
        if($EnableInheritPermissions.IsPresent -and $EnableInheritPermissions) {
            $StubSecret.enableInheritPermissions = $true
        }
        if($EnableInheritSecretPolicy.IsPresent -and $EnableInheritSecretPolicy) {
            $StubSecret.enableInheritSecretPolicy = $true
        }
        if($AutoChangeEnabled.IsPresent -and $AutoChangeEnabled) {
            $StubSecret.autoChangeEnabled = $true
        }
        # Add constructed parameters
        if(-not [String]::IsNullOrEmpty($StubSecret.sshKeyArgs)) {
            if($GeneratePassphrase.IsPresent -and $GeneratePassphrase) {
                $StubSecret.sshKeyArgs.generatePassphrase = $true
            }
            if($GenerateSshKeys.IsPresent -and $GenerateSshKeys) {
                $StubSecret.sshKeyArgs.generateSshKeys = $true
            }
        }
        # Create Json payload
        $Payload = $StubSecret | ConvertTo-Json -Depth 3
        Write-Debug ("Payload for API call:`n {0}" -f ($Payload | Out-String))

        # Connect using RestAPI
        Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $Uri, $ContentType, ($Headers | Out-String))
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method POST -Uri $Uri -ContentType $ContentType -Headers $Headers -Body $Payload
        if($WebResponse.StatusCode -eq 200) {
            # Return content
            return ($WebResponse.Content | ConvertFrom-Json)
        } else {
            # WebRequest error
            Throw $WebResponse
        }
    } catch [System.Net.WebException] {
        # WebException
        Throw $_.ErrorDetails.Message
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

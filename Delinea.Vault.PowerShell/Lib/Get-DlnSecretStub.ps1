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
Return the default values for a new secret.

.DESCRIPTION
This Cmdlet return the default values for a new secret.

.PARAMETER Name
Specify the User by its username.

.INPUTS
None

.OUTPUTS
[Object]XpmUser

.EXAMPLE
PS C:\> Get-XPMUser 
Outputs all Users objects existing on the system

.EXAMPLE
PS C:\> Get-XPMUser -Name "john.doe@domain.name"
Return user with username john.doe@domain.name if exists

.EXAMPLE
PS C:\> Get-XPMUser -Name "%test%"
Return all users with Name containing "test" if exists

.EXAMPLE
PS C:\> Get-XPMUser -ID 12345678-ABCD-EFGH-IJKL-1234567890AB
Return user with ID "12345678-ABCD-EFGH-IJKL-1234567890AB" if exists
#>
function Get-DlnSecretStub {
	param (
		[Parameter(HelpMessage = "Containing folder ID. May be null unless secrets are required to be in folders.")]
		[String]$FolderId,

        [Parameter(Mandatory, HelpMessage = "Secret template ID.")]
		[String]$SecretTemplateId
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

        # Setup values for API request
        $Uri = ("{0}/api/v1/secrets/stub" -f $VaultConnection.Url)
        $ContentType = "application/json"
        $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

        $Parameters = ("secretTemplateId={0}" -f $SecretTemplateId)
        # Add optional parameters
        if (-not [String]::IsNullOrEmpty($FolderId)) {
            $Parameters += ("&folderId={0}" -f $FolderId)
        }

        # Set Request URL
        $RequestUrl = ("{0}?{1}" -f $Uri, $Parameters)

        # Connect using RestAPI
        Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $RequestUrl, $ContentType, ($Headers | Out-String))
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method GET -Uri $RequestUrl -ContentType $ContentType -Headers $Headers
        if($WebResponse.StatusCode -eq 200) {
            # Return content
            return ($WebResponse.Content | ConvertFrom-Json)
        } else {
            # WebRequest error
            Throw $WebResponse
        }
    } catch {
        if($_.Exception.Response.StatusCode -match "Bad Request|Unauthorized|Forbidden|Internal Server Error") {
            # WebRequest exception with status code 400, 401, 403 or 500
            Throw $_
        } else {
            # Unhandled exception
            Throw $_.Exception
        }
    }
}

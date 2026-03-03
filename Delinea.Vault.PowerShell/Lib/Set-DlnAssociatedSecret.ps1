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
This Cmdlet retrieves important information about User(s) on the system.

.DESCRIPTION
This Cmdlet retrieves important information about User(s) on the system. Can return a single user by specifying the Username.

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
function Set-DlnAssociatedSecret {
	param (
		[Parameter(Mandatory = $true, HelpMessage = "Specify the object by ID to get all details.")]
		[System.Int32]$Id,
		
		[Parameter(Mandatory = $true, HelpMessage = "Specify the list of associated SecretID to use for Remote Password Changing (will be set in order).")]
		[System.Int32[]]$ResetSecretId
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
        $RequestUrl = ("{0}/api/v1/secrets/{1}/rpc-script-secrets" -f $VaultConnection.Url, $Id)
        $ContentType = "application/json"
        $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

        # Set PUT Parameters
        $Parameters = @{"data" = @{"resetSecretIds" = @{"Value" = $ResetSecretId; "Dirty" = $true}}}

        # Set Json Payload
        $Payload = $Parameters | ConvertTo-Json -Depth 3

        # Connect using RestAPI
        Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}`n Payload: {3}" -f $RequestUrl, $ContentType, ($Headers | Out-String), ($Payload | Out-String))
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $RequestUrl -ContentType $ContentType -Headers $Headers -Body $Payload
        if ($WebResponse.StatusCode -eq 200) {
            # Get raw data
            $WebResponseResult = $WebResponse.Content | ConvertFrom-Json 
            return $WebResponseResult
        } else {
            # Query error
            Throw $WebResponse
        }
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

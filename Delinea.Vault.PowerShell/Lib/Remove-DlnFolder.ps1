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
This Cmdlet removes a Folder from the system.

.DESCRIPTION
This Cmdlet removes a Folder from the system.

.PARAMETER Id
Specify the Folder Id.
.INPUTS
None

.OUTPUTS
[Object]DlnFolder

.EXAMPLE


.EXAMPLE


.EXAMPLE


.EXAMPLE

#>
function Remove-DlnFolder {
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Specify the Folder Id.")]
		[System.Int32]$Id
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
        $Uri = ("{0}/api/v1/folders/{1}" -f $VaultConnection.Url, $Id)
        $ContentType = "application/json"
        $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

        # Connect using RestAPI
        Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $Uri, $ContentType, ($Headers | Out-String))
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method DELETE -Uri $Uri -ContentType $ContentType -Headers $Headers
        $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
        if ($WebResponseResult.id -eq $Id) {
            # Return nothing
            return
        } else {
            # Query error
            Throw $WebResponseResult
        }
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

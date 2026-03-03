###########################################################################################
# Delinea Vault PowerShell module
#
# Author   : Fabrice Viguier
# Contact  : support AT ams-consulting.uk
# Release  : 22/05/2025
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
This Cmdlet retrieves important information about Roles(s) on the system.

.DESCRIPTION
This Cmdlet retrieves important information about Roles(s) on the system.

.PARAMETER PageSize
Specify the number of objects by pages when using pagination (default is 100).

.PARAMETER SortDirection
Specify the sorting direction between 'Asc' and 'Desc' (default is 'Asc').

.PARAMETER SortBy
Specify the field to sort by (default is 'name').

.PARAMETER IncludeInactive
Specify if results should include inactive groups.

.INPUTS
None

.OUTPUTS
[Object]DlnRole

.EXAMPLE
PS C:\> Get-DlnRole 
Outputs all Roles objects existing on the system

.EXAMPLE
PS C:\> Get-DlnRole -IncludeInactive
Return all Roles objects including all inactives one if exists
#>
function Get-DlnRole {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Specify the number of objects by pages when using pagination (default is 100).")]
		[System.Int32]$PageSize = 100,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the sorting direction between 'Asc' and 'Desc' (default is 'Asc').")]
		[ValidateSet('Asc','Desc')]
		[System.String]$SortDirection = "Asc",

		[Parameter(Mandatory = $false, HelpMessage = "Specify the field to sort by (default is 'name').")]
		[System.String]$SortBy = "name",
		
		[Parameter(Mandatory = $false, HelpMessage = "Specify if results should include inactive roles.")]
		[Switch]$IncludeInactive
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
	    $Uri = ("{0}/api/v1/roles" -f $VaultConnection.Url)
	    $ContentType = "application/json"
	    $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

	    # Set GET Parameters
		$Parameters = ("paging.sortBy%5B0%5D.direction={0}&paging.sortBy%5B0%5D.name={1}&paging.take={2}" -f $SortDirection, $SortBy, $PageSize)
        if ($IncludeInactive) {
		    # Include Inactive objects
		    $Parameters += "&paging.filter.includeInactive=true"
	    } else {
		    # Don't include Inactive objects by default
		    $Parameters += "&paging.filter.includeInactive=false"
	    }

        # Set Request URL
        $RequestUrl = ("{0}?{1}" -f $Uri, $Parameters)

	    # Connect using RestAPI
	    $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $RequestUrl -ContentType $ContentType -Headers $Headers
	    $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
	    if ($WebResponseResult.Success) {
		    # Get raw data
		    return $WebResponseResult.Records
	    } else {
		    # Query error
		    Throw $WebResponseResult
	    }
    } catch [System.Net.WebException] {
        # WebException
        Throw $_.ErrorDetails
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

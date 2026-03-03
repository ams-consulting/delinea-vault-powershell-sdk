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
This Cmdlet retrieves important information about SecretPolicy on the system.

.DESCRIPTION
This Cmdlet retrieves important information about SecretPolicy on the system. 

.PARAMETER Id
Specify the object by ID to get all details.

.PARAMETER SearchText
Specify the search text to use to filter results.

.PARAMETER PageSize 
Specify the number of objects by pages when using pagination (default is 100).

.PARAMETER IncludeInactive
Specify if results should include inactive users (default is false).

.PARAMETER SortDirection
Specify the sorting direction between 'Asc' and 'Desc' (default is 'Asc').

.PARAMETER SortBy
Specify the field to sort by (default is 'name').

.INPUTS
None

.OUTPUTS
[Object]SecretPolicy

.EXAMPLE


.EXAMPLE


.EXAMPLE


.EXAMPLE

#>
function Get-DlnSecretPolicy {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Specify the object by ID to get all details.")]
		[System.String]$Id,
		
		[Parameter(Mandatory = $false, HelpMessage = "Specify the search text to use to filter results.")]
		[System.String]$SearchText,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the number of objects by pages when using pagination (default is 100).")]
		[System.Int32]$PageSize = 100,		

		[Parameter(Mandatory = $false, HelpMessage = "Specify if results should include inactive users (default is false).")]
		[Switch]$IncludeInactive,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the sorting direction between 'Asc' and 'Desc' (default is 'Asc').")]
		[ValidateSet('Asc','Desc')]
		[System.String]$SortDirection = "Asc",

		[Parameter(Mandatory = $false, HelpMessage = "Specify the field to sort by (default is 'name').")]
		[System.String]$SortBy = "name"
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

		if ([System.String]::IsNullOrEmpty($Id)) {
			# Getting object collection
			# Setup values for API request
			$Uri = ("{0}/api/v1/secret-policy/search" -f $VaultConnection.Url)
			$ContentType = "application/json"
			$Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

			# Set GET Parameters
			$Parameters = ("sortBy%5B0%5D.direction={0}&sortBy%5B0%5D.name={1}&take={2}" -f $SortDirection, $SortBy, $PageSize)
			# Add boolean parameters
			if ($IncludeInactive) {
				# IncludeInactive secrets
				$Parameters += "&filter.includeInactive=true"
			} else {
				# Don't include Inactive secrets by default
				$Parameters += "&filter.includeInactive=false"
			}
			# Add optional filters to parameters
			if ([System.String]::IsNullOrEmpty($SearchText)) {
				# Add Search text as an empty value
				$Parameters += "&filter.secretPolicyName="
			} else {
				# Add Search text from Cmdlet parameter
				$Parameters += ("&filter.secretPolicyName={0}" -f [Uri]::EscapeDataString($SearchText))
			}

			# Set Request URL
			$RequestUrl = ("{0}?{1}" -f $Uri, $Parameters)

			# Connect using RestAPI
			Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $RequestUrl, $ContentType, ($Headers | Out-String))
			$WebResponse = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $RequestUrl -ContentType $ContentType -Headers $Headers
			$WebResponseResult = $WebResponse.Content | ConvertFrom-Json
			if ($WebResponseResult.Success) {
				# Get raw data
				if ($WebResponseResult.pageCount -eq 1) {
					# Return object collection
					return ($WebResponseResult.Records | Format-List)
				} else {
					# Pagination enabled, getting all pages and returning paginated collection
					$Collection = ($WebResponseResult.Records | Format-List)
					$nextPage = 1
					do {
						# Adding skip value to loop request
						$nextPageRequest = ("{0}&skip={1}" -f $RequestUrl, ($nextPage * $PageSize))
						Write-Debug ("Getting API request next page with Uri: {0}" -f $nextPageRequest, $ContentType, ($Headers | Out-String))
						$nextPageResponse = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $nextPageRequest -ContentType $ContentType -Headers $Headers
						$nextPageResponseResult = $nextPageResponse.Content | ConvertFrom-Json
						if ($nextPageResponseResult.Success) {
							# Adding results to collection
							$Collection += ($nextPageResponseResult.Records | Format-List)
						} else {
							# Query error
							Throw $nextPageResponseResult
						}
						# Incrementing page value
						$nextPage += 1
					} while ($nextPage -lt $WebResponseResult.pageCount)
					# Return Collection
					return $Collection
				}
			} else {
				# Query error
				Throw $WebResponseResult
			}
		} else {
			# Getting object by ID
			# Setup values for API request
			$Uri = ("{0}/api/v1/secret-policy/{1}" -f $VaultConnection.Url, $Id)
			$ContentType = "application/json"
			$Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

			# Connect using RestAPI
			Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $Uri, $ContentType, ($Headers | Out-String))
			$WebResponse = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $Uri -ContentType $ContentType -Headers $Headers
			$WebResponseResult = $WebResponse.Content | ConvertFrom-Json
			if ($WebResponseResult.secretPolicyId -eq $Id) {
				# Get raw data
				return $WebResponseResult
			} else {
				# Query error
				Throw $WebResponseResult
			}
		}
	} catch {
		# Unhandled exception
		Throw $_.Exception
	}
}

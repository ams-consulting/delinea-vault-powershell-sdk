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
Search, filter, sort, and page secret folders

.DESCRIPTION
Search, filter, sort, and page secret folders

.PARAMETER folderTypeId
The icon to display for the folder. Depricated in latest UI. Use 1 when setting this value.

.PARAMETER limitToDirectDescendents
When true and ParentFolderId is not null only return immediate child folders

.PARAMETER onlyIncludeRootFolders
When true only root folders will be returned and ParentFolderId will be ignored

.PARAMETER ParentFolderId
Return folders that are descendants of this folder.

.PARAMETER permissionRequired
Specify whether to filter by Owner, Edit, AddSecret, View folder permission. Default is View.

.PARAMETER searchText
Search term to match against folder names. Search returns any folder where the search term is contained in the folder name.

.PARAMETER skip
Number of records to skip before taking results

.PARAMETER sortBy[0].direction
Sort direction

.PARAMETER sortBy[0].name
Sort field name

.PARAMETER sortBy[0].priority
Priority index. Sorts with lower values are executed earlier

.PARAMETER take
Maximum number of records to include in results

.INPUTS
None

.OUTPUTS
[Object]DlnFolder

#>
function Get-DlnFolder {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Specify the search text to use to filter results.")]
		[System.String]$SearchText,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the number of objects by pages when using pagination (default is 100).")]
		[System.Int32]$PageSize = 100,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the sorting direction between 'Asc' and 'Desc' (default is 'Asc').")]
		[ValidateSet('Asc','Desc')]
		[System.String]$SortDirection = "Asc",

		[Parameter(Mandatory = $false, HelpMessage = "Specify the field to sort by (default is 'name').")]
		[System.String]$SortBy = "name",
		
		[Parameter(Mandatory = $false, HelpMessage = "Specify parent folder ID from which to search folders.")]
		[System.String]$ParentFolderId,
		
		[Parameter(Mandatory = $false, HelpMessage = "Specify if results should include all folders or only root folders.")]
		[Switch]$OnlyIncludeRootFolders
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
	    $Uri = ("{0}/api/v1/folders" -f $VaultConnection.Url)
	    $ContentType = "application/json"
	    $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

		# Set GET Parameters
		$Parameters = ("sortBy%5B0%5D.direction={0}&sortBy%5B0%5D.name={1}&take={2}" -f $SortDirection, $SortBy, $PageSize)
		# Add boolean parameters
		if ($OnlyIncludeRootFolders) {
			# Include Root folders
			$Parameters += "&filter.onlyIncludeRootFolders=true"
		} else {
			# Include all folders
			$Parameters += "&filter.onlyIncludeRootFolders=false"
		}
		# Add optional filters to parameters
		if ([System.String]::IsNullOrEmpty($SearchText)) {
			# Add Search text as an empty value
			$Parameters += "&filter.searchText="
		} else {
			# Add Search text from Cmdlet parameter
			$Parameters += ("&filter.searchText={0}" -f [Uri]::EscapeDataString($SearchText))
		}
		if ([System.String]::IsNullOrEmpty($ParentFolderId)) {
			# Add Search text as an empty value
			$Parameters += "&filter.parentFolderId="
		} else {
			# Add Search text from Cmdlet parameter
			$Parameters += ("&filter.parentFolderId={0}" -f [Uri]::EscapeDataString($ParentFolderId))
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
				return $WebResponseResult.Records
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
						$Collection += $nextPageResponseResult.Records
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
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

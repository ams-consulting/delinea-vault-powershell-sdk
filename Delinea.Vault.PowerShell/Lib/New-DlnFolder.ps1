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
This Cmdlet creates a new Folder on the system.

.DESCRIPTION
This Cmdlet creates a new Folder on the system.

.PARAMETER Name
Specify the Folder name.

.PARAMETER ParentFolderId
Specify the Folder ID where to create Secret (Root folder by default).

.PARAMETER Path
Specify the Folder full Path, starting with Root folder and ending with Folder name. All folders in the Path must exist (example '\Service Accounts\MS-SQL').

.PARAMETER FolderTypeId
Specify the Folder type ID (1 by default).

.PARAMETER InheritPermissions
Specify if Inherit Permissions should be enabled (default is true).

.INPUTS
None

.OUTPUTS
[Object]DlnFolder

.EXAMPLE


.EXAMPLE


.EXAMPLE


.EXAMPLE

#>
function New-DlnFolder {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Specify the Folder name.")]
        [Parameter(ParameterSetName = "Name")]
		[System.String]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the Folder ID where to create Secret (Root folder by default).")]
        [Parameter(ParameterSetName = "Name")]
		[System.Int32]$ParentFolderId = -1,

		[Parameter(Mandatory = $false, HelpMessage = "Specify the Folder full Path, starting with Root folder and ending with Folder name. All folders in the Path must exist (example '\\Service Accounts\\MS-SQL').")]
        [Parameter(ParameterSetName = "Path")]
		[System.String]$Path,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the Folder type ID (1 by default).")]
		[System.Int32]$FolderTypeId = 1,

		[Parameter(Mandatory = $false, HelpMessage = "Specify if Inherit Permissions should be enabled (default is true).")]
		[Switch]$InheritPermissions,

		[Parameter(Mandatory = $false, HelpMessage = "Specify if Inherit Secret Policy should be enabled (default is true).")]
		[Switch]$InheritSecretPolicy
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

        if(-not [System.String]::IsNullOrEmpty($Name)) {
            # Creating Folder by Name
            # Setup values for API request
            $Uri = ("{0}/api/v1/folders" -f $VaultConnection.Url)
            $ContentType = "application/json"
            $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

            # Set POST Parameters
            $Data = @{}
            # Add parameters
            $Data.folderName = $Name
            $Data.folderTypeId = $FolderTypeId
            $Data.parentFolderId = $ParentFolderId
            # Add boolean values
            if($InheritPermissions.IsPresent -and $InheritPermissions) {
                $Data.inheritPermissions = $true
            } elseif(-not $InheritPermissions.IsPresent) {
                # Default value
                $Data.inheritPermissions = $true
            } else {
                $Data.inheritPermissions = $false
            }
            if($InheritSecretPolicy.IsPresent -and $InheritSecretPolicy) {
                $Data.inheritSecretPolicy = $true
            } elseif(-not $InheritSecretPolicy.IsPresent) {
                # Default value
                $Data.inheritSecretPolicy = $true
            } else {
                $Data.inheritSecretPolicy = $false
            }
            # Create Json payload
            $Payload = $Data | ConvertTo-Json -Depth 3
            Write-Debug ("Payload for API call:`n {0}" -f ($Payload | Out-String))

            # Connect using RestAPI
            Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $Uri, $ContentType, ($Headers | Out-String))
            $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Uri -ContentType $ContentType -Headers $Headers -Body $Payload
            $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
            if ($WebResponseResult.id -match "[0-9]") {
                # Return Folder
                return $WebResponseResult
            } else {
                # Query error
                Throw $WebResponseResult
            }
        } else {
            # Creating Folder by Path
            $Name = ($Path -split '\\\\')[-1]
            $ParentFolder = ($Path -split '\\\\')[-2]
            if([System.String]::IsNullOrEmpty($ParentFolder)) {
                # Parent folder is Root folder
                $ParentFolderId = -1
            } else {
                $ParentFolderId = (Get-DlnFolder -SearchText $ParentFolder).Id
            }
            # Create Folder by Name with ParentFolderId from search
            New-DlnFolder -Name $Name -ParentFolderId $ParentFolderId -FolderTypeId $FolderTypeId
        }
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

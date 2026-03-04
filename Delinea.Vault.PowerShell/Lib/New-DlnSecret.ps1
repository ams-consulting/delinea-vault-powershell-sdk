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
This Cmdlet creates a new Secret on the system.

.DESCRIPTION
This Cmdlet creates a new Secret on the system. 

.PARAMETER templateId
Specify the Template ID to use to create Secret.

.PARAMETER folderId
Specify the Folder ID where to create Secret.

.PARAMETER name
Specify the Secret name.

.PARAMETER fields
Specify the fields for this secret as an array of slug-value pairs (e.g. import from CSV file with headers as 'slug' and 'value').

.PARAMETER siteId
Specify the Site to use when managing this Secret.

.PARAMETER inheritSecretPolicy
Specify if Inherit Secret Policy should be enabled (default is true).

.PARAMETER generateSshKeys
Specify if SSH Keys should be generated (default is false).

.PARAMETER autoChangePassword
Specify if password should be changed automatically (default is false).

.INPUTS
None

.OUTPUTS
[Object]DlnSecret

.EXAMPLE


.EXAMPLE


.EXAMPLE


.EXAMPLE

#>
function New-DlnSecret {
	param (
		[Parameter(Mandatory = $true, HelpMessage = "Specify the Template ID to use to create Secret.")]
		[System.Int32]$TemplateId,
		
		[Parameter(Mandatory = $true, HelpMessage = "Specify the Folder ID where to create Secret.")]
		[System.Int32]$FolderId,

		[Parameter(Mandatory = $true, HelpMessage = "Specify the Secret name.")]
		[System.String]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the fields for this secret as an array of slug-value pairs (e.g. import from CSV file with headers as 'slug' and 'value').")]
		[System.Object]$Fields,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the Site to use when managing this Secret.")]
		[System.String]$SiteId = "0",

		[Parameter(Mandatory = $false, HelpMessage = "Specify if Inherit Secret Policy should be enabled (default is true).")]
		[Switch]$InheritSecretPolicy,

		[Parameter(Mandatory = $false, HelpMessage = "Specify if SSH Keys should be generated (default is false).")]
		[Switch]$GenerateSshKeys,
        
		[Parameter(Mandatory = $false, HelpMessage = "Specify if password should be changed automatically (default is false).")]
		[Switch]$AutoChangePassword
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
        $Uri = ("{0}/internals/secret-detail" -f $VaultConnection.Url, $Id)
        $ContentType = "application/json"
        $Headers = @{ "Authorization" = ("Bearer {0}" -f $VaultConnection.access_token) }

        # Set GET Parameters
        $Data = @{}
        # Add parameters
        $Data.name = $Name
        $Data.folderId = $FolderId
        $Data.templateId = $TemplateId
        $Data.site = $SiteId
        # Parsing fields parameters
        $ParsedFields = @()
        foreach($Entry in $Fields) {
            # Adding entry as hashtable
            $ParsedFields += @{"slug"=$Entry.slug; "value"=$Entry.value}
        }
        $Data.fields = $ParsedFields
        # Add boolean values
        if($InheritSecretPolicy.IsPresent -and $InheritSecretPolicy) {
            $Data.enableInheritSecretPolicy = $true
        } elseif(-not $InheritSecretPolicy.IsPresent) {
            # Default value
            $Data.enableInheritSecretPolicy = "true"
        } else {
            $Data.enableInheritSecretPolicy = "false"
        }
        if($GenerateSshKeys.IsPresent -and $GenerateSshKeys) {
            $Data.generateSshKeys = "true"
        } else {
            # Default value
            $Data.generateSshKeys = "false"
        }
        if($AutoChangePassword.IsPresent -and $AutoChangePassword) {
            $Data.autoChangePassword = "true"
        } else {
            # Default value
            $Data.autoChangePassword = ""
        }
        # Create Json payload
        $Payload = @{"data" = $Data} | ConvertTo-Json -Depth 3
        Write-Debug ("Payload for API call:`n {0}" -f ($Payload | Out-String))

        # Connect using RestAPI
        Write-Debug ("Calling API endpoint`n Uri: {0}`n ContentType: {1}`n Headers: {2}" -f $Uri, $ContentType, ($Headers | Out-String))
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Uri -ContentType $ContentType -Headers $Headers -Body $Payload
        $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
        if ($WebResponseResult -match "[0-9]") {
            # Return Secret Id
            return $WebResponseResult
        } else {
            # Query error
            Throw $WebResponseResult
        }
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}

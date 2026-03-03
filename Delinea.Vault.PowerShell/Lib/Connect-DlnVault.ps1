###########################################################################################
# Delinea Vault PowerShell module
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

<#
.SYNOPSIS
This Cmdlet is creating a secure connection with a Delinea Vault tenant specified by its Secret Server Url.

.DESCRIPTION
This Cmdlet support different methods of authentication to connect to a Delinea Secret Server Vault tenant. 
The methods available are:
- Interactive authentication using Single-Factor Authentication.
    This connection is made by specifying a User name and using simple password authentication.

- Interactive authentication using Two-Factor Authentication.
    This connection is made by specifying a User name and password authentication, then will be prompted for OTP code for second factor authentication.

.PARAMETER Url
Specify the Secret Server URL to use for the connection (e.g. https://tenant.secretservercloud.com/SecretServer/).

.PARAMETER User
Specify the User login to use for the connection (e.g. admin@tenant.secretservercloud.com).

.PARAMETER UseTwoFactor
Specify to use two-factor authentication or not.

.INPUTS

.OUTPUTS
[Object]VaultConnection
This object is returned as a Global variable in the PS Session in case of succesful connection to Delinea Vault.

.EXAMPLE
PS C:\> Connect-DlnVault -Url https://tenant.secretservercloud.com/SecretServer/ -User admin@tenant.secretservercloud.com

#>
function Connect-DlnVault {
	param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the Secret Server URL to use for the connection (e.g. https://tenant.secretservercloud.com/SecretServer/).")]
        [Parameter(ParameterSetName = "Interactive")]
        [System.String]$Url,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the User login to use for the connection (e.g. admin@tenant.secretservercloud.com).")]
        [Parameter(ParameterSetName = "Interactive")]
        [System.String]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Specify to use two-factor authentication or not.")]
        [Parameter(ParameterSetName = "Interactive")]
        [Switch]$UseTwoFactor,

        [Parameter(Mandatory = $false, HelpMessage = "Specify to use refresh token to renew expired access token.")]
        [Parameter(ParameterSetName = "Token")]
        [Switch]$RefreshToken
	)
	
    try {	
        # Set Security Protocol for RestAPI (must use TLS 1.2)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if ($RefreshToken) {
            # Test current connection to the Delinea Vault
            if ($Global:VaultConnection -eq [Void]$null) {
                # Inform connection does not exists and suggest to initiate one
                Write-Warning ("No connection could be found with the Delinea Secret Server Vault. Use Connect-DSSVault Cmdlet to create a valid connection.")
                Break
            }

            # Setup variable for interactive connection using MFA
            $Uri = ("{0}/oauth2/token" -f $VaultConnection.Url)
            $ContentType = "application/json"
            $Headers = @{}

            # Format Json query
            $Auth = @{}
            $Auth.grant_type = "refresh_token"
            $Auth.refresh_token = $VaultConnection.refresh_token
            #$Json = $Auth | ConvertTo-Json

            # Initiate connection
            Write-Verbose("Connecting to Secret Server URL: {0}" -f $VaultConnection.Url)
            Write-Verbose("Payload:`n{0}" -f ($Auth | Out-String))
            Write-Verbose("Content type: {0}" -f $ContentType)
            Write-Verbose("Headers: {0}" -f ($Headers | Out-String))

            # Get Response
            $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Uri -Body $Auth -ContentType $ContentType -Headers $Headers
            $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
            Write-Verbose("JSON Response:`n{0}" -f ($WebResponseResult | ConvertTo-Json -Depth 100))
            if (-not [System.String]::IsNullOrEmpty($WebResponseResult.access_token)) {
                # Silently refresh Session Token from successfull login
                $Global:VaultConnection.access_token = $WebResponseResult.access_token
                $Global:VaultConnection.token_type = $WebResponseResult.token_type
                $Global:VaultConnection.expires_in = $WebResponseResult.expires_in
                $Global:VaultConnection.expires_at = [DateTime]::Now.AddSeconds($WebResponseResult.expires_in)
                $Global:VaultConnection.refresh_token = $WebResponseResult.refresh_token
            } else {
                # Unsuccesful connection
                Throw $WebResponseResult
            }
        } else {
            # Delete any existing connexion cache
            if ($Global:VaultConnection -ne [Void]$null) {
                $Global:VaultConnection = $null
            }

            # Setup variable for interactive connection using MFA
            $Uri = ("{0}/oauth2/token" -f $Url)
            $ContentType = "application/json"

            # Prompt User for Password
            Write-Host("Connecting to Delinea Secret Server URL ({0}) as {1}`n" -f $Url, $User)
            $SecureString = Read-Host -Prompt "Password" -AsSecureString
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))

            # Format Json query
            $Auth = @{}
            $Auth.grant_type = "password"
            $Auth.username = $User
            $Auth.password = $Password

            # Prompt User for OTP code if two-factor authentication is enabled
            if ($UseTwoFactor) {
                $code = Read-Host -Prompt "Enter your OTP for 2FA"
                $Headers = @{"OTP" = $code}    
            } else {
                $Headers = @{}
            }

            # Initiate connection
            Write-Verbose("Connecting to Secret Server URL: {0}" -f $Uri)
            Write-Verbose("Payload:`n{0}" -f ($Auth | Out-String))
            Write-Verbose("Content type: {0}" -f $ContentType)
            Write-Verbose("Headers: {0}" -f ($Header | Out-String))

            # Get Response
            $WebResponse = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Uri -Body $Auth -ContentType $ContentType -Headers $Headers
            $WebResponseResult = $WebResponse.Content | ConvertFrom-Json
            Write-Verbose("JSON Response:`n{0}" -f ($WebResponseResult | ConvertTo-Json -Depth 100))
            if (-not [System.String]::IsNullOrEmpty($WebResponseResult.access_token)) {
                # Get Session Token from successfull login
                $Global:VaultConnection = @{}
                $Global:VaultConnection.url   = $Url
                $Global:VaultConnection.user  = $User
                $Global:VaultConnection.access_token = $WebResponseResult.access_token
                $Global:VaultConnection.token_type = $WebResponseResult.token_type
                $Global:VaultConnection.expires_in = $WebResponseResult.expires_in
                $Global:VaultConnection.expires_at = [DateTime]::Now.AddSeconds($WebResponseResult.expires_in)
                $Global:VaultConnection.refresh_token = $WebResponseResult.refresh_token

                # Return information values to confirm connection success
                return $Global:VaultConnection
            } else {
                # Unsuccesful connection
                Throw $WebResponseResult
            }
        }
    } catch [System.Net.WebException] {
        if ($_.ErrorDetails.Message -match "invalid_grant") {
            # Unsuccesful refresh due to expired token, new connection needed
            Write-Warning ("Your session with the Delinea Secret Server Vault has expired and you have hit the limit of refresh tokens allowed. Use Connect-DSSVault Cmdlet to re-connect.")
            Break
        }
        # WebException
        Throw $_.ErrorDetails
    } catch {
        # Unhandled exception
        Throw $_.Exception
    }
}
# Copyright (c) 2025 Broadcom. All Rights Reserved.
# Broadcom Confidential. The term "Broadcom" refers to Broadcom Inc.
# and/or its subsidiaries.
#
###
#
# SOFTWARE LICENSE AGREEMENT
#
# 
#
# Copyright (c) CA, Inc. All rights reserved.
#
# 
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license under CA, Inc.’s
# copyrights to use, copy, modify, and distribute this software in source code or binary form 
# for use in connection with CA, Inc. products.
#
# 
# This copyright notice shall be included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
####
#
# Intended use:
#
# This internal script pulls download tokens from GTO's API servers based off.
#
# Last modified: 2025-05-07
#
#

Param (
    [Parameter (Mandatory = $False)] [ValidateNotNullOrEmpty()] [Switch]$Silence
)

Function New-LogFile {

    <#
        .SYNOPSIS
        At script launch, the function New-LogFile creates a log file if not already present.

        .DESCRIPTION
        The function New-LogFile creates a log file in logs sub-directory off of the PSScriptRoot directory
        with a timestamp in the format of Year-Month-Day. Should a logs sub-directory already exist, logs 
        for this script may be identified by the prefix "DepotChange-"

        .EXAMPLE
        New-LogFile
    #>

    # create one log file for each day the script is run.
    $FileTimeStamp = Get-Date -Format "MM-dd-yyyy"
    $Global:LogFolder = Join-Path -Path $PSScriptRoot -ChildPath 'logs'
    $Global:LogFile = Join-Path -Path $LogFolder -ChildPath "DepotChange-$FileTimeStamp.log"
    $LogFolderExists = Test-Path $LogFolder

    if (!$LogFolderExists) {
        Write-Host "LogFolder not found, creating $LogFolder" -ForegroundColor Yellow;
        New-Item -ItemType Directory -Path $LogFolder | Out-Null
        if (!$?) {
            Write-Output "Failed to create log directory. Exiting."
            exit
        }
    }

    # Create the log file if not already present.
    if (! (Test-Path $LogFile)) {
        New-Item -type File -Path $LogFile | Out-Null
    }
}

Function Write-LogMessage {

    <#
        .SYNOPSIS
        The function Write-LogMessage writes a message to a log file and optionally displays it.

        .DESCRIPTION
        The function Write-LogMessage facilitates severity-level color-coded Messages to be sent to the
        screen, with a plain-text Message logged to a file.

        .EXAMPLE
        Write-LogMessage -Type ERROR -Message "No JSON input file $SddcManagerCredentialsJson detected."

        .EXAMPLE
        Write-LogMessage -Type ERROR -SuppressOutputToScreen -Message "No JSON input file $SddcManagerCredentialsJson detected."

        .EXAMPLE
        Write-LogMessage -Type ERROR -PrependNewLine -Message "No JSON input file $SddcManagerCredentialsJson detected."

        .EXAMPLE
        Write-LogMessage -Type ERROR -AppendNewLine -Message "No JSON input file $SddcManagerCredentialsJson detected."

        .PARAMETER AppendNewLine
        Specifies if a blank line should be written to the screen after the message is displayed.

        .PARAMETER PrependNewLine
        Specifies if a blank line should be written to the screen before the message is displayed.

        .PARAMETER Message
        Specifies the message logged and optionally displayed to the user.

        .PARAMETER SuppressOutputToScreen
        Specifies if the message should only be logged (and not displayed to the user).

        .PARAMETER Type
        Specifies a list of severity of the logged and optionally displayed to the user. In the case of
        a displayed Message, the severity will be color coded accordingly.
    #>

    Param (
        [Parameter (Mandatory = $False)] [Switch]$AppendNewLine,
        [Parameter (Mandatory = $True)] [AllowEmptyString()] [String]$Message,
        [Parameter (Mandatory = $False)] [Switch]$PrependNewLine,
        [Parameter (Mandatory = $False)] [Switch]$SuppressOutputToScreen,
        [Parameter (Mandatory = $False)] [ValidateSet("INFO", "ERROR", "WARNING", "EXCEPTION","ADVISORY")] [String]$Type = "INFO"
    )

    $MsgTypeToColor=@{
        "INFO" = "Green"; 
        "ERROR" = "Red" ; 
        "WARNING" = "Yellow" ; 
        "ADVISORY" = "Yellow" ;
        "EXCEPTION" = "Cyan"
    }
    $MessageColor=$MsgTypeToColor.$Type

    $TimeStamp = Get-Date -Format "MM-dd-yyyy_HH:mm:ss"

    if ($PrependNewLine -and $($Global:LogOnly -eq "disabled")) {
        Write-Output ""
    }

    if (!$SuppressOutputToScreen -and ($Global:LogOnly -eq "disabled")) {
        Write-Host -ForegroundColor $MessageColor "[$Type] $Message"
    }

    if ($AppendNewLine -and ($Global:LogOnly -eq "disabled")) {
        Write-Output ""
    }

    $LogContent = '[' + $TimeStamp + '] ' + '('+ $Type + ')' + ' ' + $Message
    Add-Content -Path $LogFile $LogContent
}


Function Set-Tier {

    <#
        .SYNOPSIS
        The function Set Tier 

        .DESCRIPTION
        This function takes four parameters, each from environment variables or from user input.
        DepotTier: Production or Staging
        ClientId, ClientSecret, and UserEmail.  These three values are prefaced with either staging 
        or production to allow for each switching between environments.
        Example $PROFILE
        $env:DepotTier="Production"

        $env:ClientId="<secret>"
        $env:StagingClientSecret="<secret>"
        $env:StagingUserEmail="<secret>"
        $env:ProductionClientId=""<secret>"
        $env:ProductionClientSecret="<secret>"
        $env:ProductionUserEmail=""<secret>"
        .EXAMPLE
        Set-Tier
    #>

    Write-LogMessage -Type INFO -AppendNewLine -Message "This script is for internal VMware by Broadcom use only and may not be distributed to customers."

    if (! $env:DepotTier) {
        $DepotTier = Read-Host "Enter DepotTier (Production or Staging)" 

    } else {
        $DepotTier = $env:DepotTier
    }

    if (($DepotTier -ne "Production") -and ($DepotTier -ne "Staging")) {
        Write-LogMessage -Type ERROR -AppendNewLine -Message "Invalid DepotTier `"$DepotTier`" entered.  Valid options are `"Staging`" and `"Production`"."
        exit
    }

    # Dynamically generate variable names based on tier
    New-Variable -Name "`$env:$DepotTier`ClientId" 
    $StoredClientId = Invoke-Expression (Get-Variable -Name "`$env:$DepotTier`ClientId").Name

    New-Variable -Name "`$env:$DepotTier`ClientSecret" 
    $StoredClientSecret = Invoke-Expression (Get-Variable -Name "`$env:$DepotTier`ClientSecret").Name

    New-Variable -Name "`$env:$DepotTier`UserEmail" 
    $StoredUserEmail = Invoke-Expression (Get-Variable -Name "`$env:$DepotTier`UserEmail").Name

    if (! $StoredClientId) {
        $ClientId = Read-Host "Enter ClientId"
    } else {
        $ClientId = $StoredClientId
    }

    if (! $StoredClientSecret) {
        $ClientSecret = Read-Host "Enter ClientSecret"
    } else {
        $ClientSecret = $StoredClientSecret
    }

    if (! $StoredUserEmail) {
        $UserEmail = Read-Host "Enter UserEmail "
    } else {
        $UserEmail = $StoredUserEmail
    }

    if ($DepotTier -eq "Production") {
        $ApiServerUri = "https://eapi.broadcom.com/auth/oauth/v2/token"
        $ApiNewTokenEndpointUri = "https://eapi.broadcom.com/internaltools/downloads-token/generate-token-internal?userEmail=$UserEmail"
        $ApiTokenFetchEndpointUri = "https://eapi.broadcom.com/internaltools/downloads-token/token-details-internal"
    } elseif ($DepotTier -eq "Staging") {
        $ApiServerUri = "https://eapi-gcpstg.broadcom.com/auth/oauth/v2/token"
        $ApiNewTokenEndpointUri = "https://eapi-gcpstg.broadcom.com/postg/internaltools/downloads-token/generate-token-internal?userEmail=$UserEmail"
        $ApiTokenFetchEndpointUri = "https://eapi-gcpstg.broadcom.com/postg/internaltools/downloads-token/token-details-internal"
    }

    # Get a Bearer Token.
    $BearerToken = Invoke-GetBearerToken -ApiServerUri $ApiServerUri -ClientId $ClientId -ClientSecret $ClientSecret 
    
    # Check for an existing token.
    Invoke-CheckForExistingToken -ApiTokenFetchEndpointUri $ApiTokenFetchEndpointUri -BearerToken $BearerToken -DepotTier $DepotTier -UserEmail $UserEmail

    # If the aformentioned script does not exist (in which case an existing token was found, fetch a new token.)
    Invoke-GetNewToken -ApiNewTokenEndpointUri $ApiNewTokenEndpointUri -BearerToken $BearerToken -DepotTier $DepotTier -UserEmail $UserEmail
}

Function Invoke-GetBearerToken {

    Param (
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$ApiServerUri,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$ClientId,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$ClientSecret
    )

    $Headers = @{"Content-Type" = "application/x-www-form-urlencoded" }

    $Body = @{
        client_id=$ClientId 
        client_secret=$ClientSecret 
        grant_type="client_credentials"
    }

    try {
        $Response = (Invoke-RestMethod -Uri $ApiServerUri -Method 'POST' -Headers $Headers -Body $Body)
    } catch [Exception] {
        if ($Error[0] -match "The given client credentials were not valid") {
            Write-LogMessage -Type ERROR -AppendNewLine -Message "The client secret or client id were invalid.  Please re-enter and try again"
            exit
        }
    }

    return $Response.access_token
}

Function Invoke-CheckForExistingToken {

    Param (
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$ApiTokenFetchEndpointUri,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$BearerToken,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$DepotTier,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$UserEmail
    )

    $BodyArray = [pscustomobject]@{
        loggedInUser = "$UserEmail"
        isActive = "Y"
    }

    $JsonBody = $BodyArray | ConvertTo-Json
    $Headers = @{"Authorization" = "Bearer $BearerToken"}
    $Headers.Add("Content-Type", "application/json")

    try {
        $Response = Invoke-RestMethod -Uri $ApiTokenFetchEndpointUri -Method 'POST' -Headers $Headers -Body $JsonBody
    } catch [Exception] {
        Write-LogMessage -Type ERROR -AppendNewLine -Message "An exception occurred requesting checking for a existing token."
        exit
    }

    # Check if there are non-zero active tokens available.
    if ($($Response.data.result.totalElements) -ne [int]0 ) {
        if ($($response.data.result.totalElements) -eq [int]1 ) {
            Write-LogMessage -Type INFO -AppendNewLine -Message "$DepotTier tier download token: $($Response.data.result.content.token)"
            Write-LogMessage -Type INFO -AppendNewLine -Message "Note: this is an existing token: its expiry time is $($Response.data.result.content.expiryDate) UTC"
            $Global:DownloadToken = $($Response.data.result.content.token)

        } else {
            Write-LogMessage -Type INFO -AppendNewLine -Message "$DepotTier tier download token: $($Response.data.result.content.token[0])"
            Write-LogMessage -Type INFO -AppendNewLine -Message "Note: this is an existing token: its expiry time is $($Response.data.result.content.expiryDate[0]) UTC"
            $Global:DownloadToken = $($Response.data.result.content.token[0])
        }
        exit
    }
}

Function Invoke-GetNewToken {

    Param (
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$ApiNewTokenEndpointUri,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$BearerToken,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$DepotTier,
        [Parameter (Mandatory = $True)] [ValidateNotNullOrEmpty()] [String]$UserEmail
    )

    $Headers = @{"Authorization" = "Bearer $BearerToken"}
    $Headers.Add("Content-Type", "application/json")

    try {
        $Response = (Invoke-RestMethod -Uri $ApiNewTokenEndpointUri -Method 'POST' -Headers $Headers)
    } catch [Exception] {
        if ($Error[0] -match "Invalid user role") {
            Write-LogMessage -Type ERROR -AppendNewLine -Message "This email address ($UserEmail) is not authorized to generate tokens."
        } elseif ($Error[0] -match "Only internal users can generate token") {     
            Write-LogMessage -Type ERROR -AppendNewLine -Message "Only broadcom.com addresses can be used to generate tokens." 
        } else {
            Write-LogMessage -Type ERROR -AppendNewLine -Message "ERROR: $($Error[0])".
        }
        exit
    }

    if ($Response.data.token) {
        Write-LogMessage -Type INFO -AppendNewLine -Message "$DepotTier tier download token: $($Response.data.token)"
        Write-LogMessage -Type INFO -AppendNewLine -Message "This is a new download token with 48h expiry."

        # For use with pipelines
        $Global:DownloadToken = $($Response.data.token)
    } else {
        Write-LogMessage -Type INFO -AppendNewLine -Message -Object "Did not see data token in response." -ForegroundColor Yellow
        Write-LogMessage -Type INFO -AppendNewLine -Message -Object "Full response: $Response"
    }
}

if ($Silence) {
    $Global:LogOnly = "enabled"
} else {
    $Global:LogOnly = "disabled"
}

# Invoke methods
New-LogFile
Set-Tier

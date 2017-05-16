# Terraform Azure AD Application Creation

param (

[string]$azurelocation = 'West Europe',
[string]$app_password = 'AutomationPa$$w0rd!',
[string]$subscription_ID = '733a1ea1-2d00-45b8-a6f3-c05a5ef2d5c3', 
[string]$PageName = 'http://ogdhenken.nl/Terraform2',
[string]$ResourceGroup = 'terraform-automation'

)

Add-AzureRmAccount
$azuresub = Get-AzureRmSubscription -SubscriptionId $subscription_ID

New-AzureRmADApplication -DisplayName "Terraform-auth" -HomePage $PageName -IdentifierUris $PageName -Password $app_password -Verbose

$app = Get-AzureRmADApplication -IdentifierUri $PageName -Verbose

New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -Verbose
Start-Sleep -Seconds 20

#Uncheck voor rechten op subscription
$roleassignment = New-AzureRmRoleAssignment -ServicePrincipalName $pagename -RoleDefinitionName Owner -Scope "/subscriptions/$subscription_ID" -Verbose

#geeft alle benodigde gegevens voor environment variables die Terraform nodig heeft
$result = @{SubscriptionID="$($azuresub.SubscriptionId)"; TenantID = "$($azuresub.TenantId)"; ClientID = "$($app.ApplicationId)"; client_secret = $app_password; object_id = "$($roleassignment.ObjectId)"}
$result


###################################################################################
##
## PowerShell script for exporting Azure Resources wihtin a subscription.
## Creator: Maik van der Gaag
##
###################################################################################


Login-AzureRmAccount
$path = Read-Host "Enter the full path to save the export file to"

$subsciptions = Get-AzureRmSubscription

Write-Host "Subscriptions"
Write-Host "--------------"
foreach($sub in $subsciptions){

    Write-Host ($sub | Select -ExpandProperty "Name")
}

Write-Host ""

$name = Read-Host "Please enter the subscription names for which you want to export the Azure Services devided by (,)"

$names = $name.Split(",");

foreach($subName in $names){
    Write-Host "Exporting Subscription:" -ForegroundColor Green
    Set-AzureRmContext -SubscriptionName $subName
    Get-AzureRmResource | Select-Object Name, ResourceType, ResourceGroupName, SubscriptionId | Export-Csv -Path $path -Encoding ascii -NoTypeInformation -Append
}
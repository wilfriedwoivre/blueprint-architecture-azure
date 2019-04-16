Param(
    [Parameter(Mandatory=$true)]
    [string]
    $storageName,
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroupName
)

$keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName
$context = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $keys.Value[0]

$startTime = (Get-Date).AddHours(-2)
$expiryTime = (Get-Date).AddDays(1)

$token = New-AzStorageAccountSASToken -Service Blob -ResourceType Service,Container,Object -Permission 'rl' -Protocol HttpsOnly -StartTime $startTime -ExpiryTime $expiryTime -Context $context

$parameters = @{}
$parameters.Add("storageAccountName", $storageName)
$parameters.Add("storageSASToken", $token)


New-AzDeployment -TemplateFile ".\HubSpoke\azuredeploy.json" -Name 'hubspoke' -Location 'westeurope' -TemplateParameterObject $parameters

Param(
    [Parameter(Mandatory=$true)]
    [string]
    $storageName,
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroupName
)

$containerName = "arm"
$keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName

$context = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $keys.Value[0]

ls .\HubSpoke\nested -Recurse | % {
    Set-AzStorageBlobContent -File $_.FullName -Blob "templates/$($_.Name)" -Container $containerName -BlobType Block -Context $context -Force
}


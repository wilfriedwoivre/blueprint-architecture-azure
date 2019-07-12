Get-AzResourceGroup -Tag @{"UseCase"="hubspokev2"} | % {
    Remove-AzResourceGroup -Name $_.ResourceGroupName -Force -AsJob 
}

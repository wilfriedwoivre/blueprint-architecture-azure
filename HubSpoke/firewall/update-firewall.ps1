function CheckPolicies {
    if (0 -eq (Get-Module -ListAvailable -Name powershell-yaml | Measure-Object).Count) {
        Install-Module powershell-yaml -Scope CurrentUser
    }
    Import-Module powershell-yaml
}

$ErrorActionPreference = "Stop"

CheckPolicies


$firewall = Get-AzFirewall -ResourceGroupName "hub-rg" -Name "hub-fwl"

$networkRuleContent = Get-Content ".\network-rule.yaml" -Raw
$yamlNetworkRules = ConvertFrom-Yaml -Yaml $networkRuleContent

$nwkRulesCollectionsCount = $firewall.NetworkRuleCollections.Count
$nwkRulesCount = $firewall.NetworkRuleCollections | Select-Object Rules | ForEach-Object { $_.Rules } | Measure-Object

Write-Output "Azure Firewall $firewallName contains $nwkRulesCollectionsCount network rules collection with a total of $nwkRulesCount rules."
Write-Output "Detecting file netork-rule.yaml with $($yamlNetworkRules.Count) rule collection and a total of $($yamlNetworkRules.rules.Count)"


$appRuleContent = Get-Content ".\application-rule.yaml" -Raw
$yamlApplicationRules = ConvertFrom-Yaml -Yaml $appRuleContent

$appRulesCollectionsCount = $firewall.ApplicationRuleCollections.Count
$appRulesCount = $firewall.ApplicationRuleCollections | Select-Object Rules | ForEach-Object { $_.Rules } | Measure-Object

Write-Output "Azure Firewall $firewallName contains $appRulesCollectionsCount application rules collection with a total of $appRulesCount rules."
Write-Output "Detecting file netork-rule.yaml with $($yamlApplicationRules.Count) rule collection and a total of $($yamlApplicationRules.rules.Count)"


$firewall.NetworkRuleCollections.Clear()
foreach ($yamlRawRule in $yamlNetworkRules) {
    $rules = @()

    foreach ($rawRule in $yamlRawRule.rules) {
        $rules += New-AzFirewallNetworkRule -Name $rawRule.name -DestinationAddress $rawRule.destinationAddresses -DestinationPort $rawRule.destinationPorts -Protocol $rawRule.protocols -SourceAddress $rawRule.sourceAddresses
    }

    $ruleCollection = New-AzFirewallNetworkRuleCollection -Name $yamlRawRule.name -Priority $yamlRawRule.priority -ActionType $yamlRawRule.action.type -Rule $rules
    $firewall.NetworkRuleCollections.Add($ruleCollection)
}

$firewall.ApplicationRuleCollections.Clear()
foreach ($yamlRawRule in $yamlApplicationRules) {
    $rules = @()

    foreach ($rawRule in $yamlRawRule.rules) {
        if (0 -eq ($rawRule.targetFqdns | Measure-Object).Count) {
            $rules += New-AzFirewallApplicationRule -Name $rawRule.name -SourceAddress $rawRule.sourceAddresses -FqdnTag $rawRule.fqdnTags
        }
        else {
            $rules += New-AzFirewallApplicationRule -Name $rawRule.name -SourceAddress $rawRule.sourceAddresses -TargetFqdn $rawRule.targetFqdns -Protocol $rawRule.protocols 
        }
    }

    $ruleCollection = New-AzFirewallApplicationRuleCollection -Name $yamlRawRule.name -Priority $yamlRawRule.priority -ActionType $yamlRawRule.action.type -Rule $rules
    $firewall.ApplicationRuleCollections.Add($ruleCollection)
}

#$firewall
Set-AzFirewall -AzureFirewall $firewall
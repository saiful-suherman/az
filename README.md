# Change NIC of Azure VM
## Script file Name
Script file name: **VmChangeNic.ps1**

## Parameters
Following parameters are expected/allowed
| Parameter | Example |
| --- | --- |
| $AzSubscription | -AzSubscription "PROD" |
| $VmName | -VmName "vm1" |
| $NewNicIpAddress | -NewNicIpAddress "192.168.255.4" |

## Script jobs
  1. Script signs in to Azure using Connect-AzAccount
  2. Script checks whether a NIC exists with the provided IP address

```powershell
  $varNewNic = Get-AzNetworkInterface -ResourceGroupName "prod-weu-vnet-001-rg" | Where-Object {$_.IpConfigurations.PrivateIpAddress -eq $newNicIpAddress}
  
  if ($varNewNic -eq $null) { 
  Write-Error "`nThe specified new Nic with IP Address $newNicIpAddress does not exist. Exiting Script...`n"
  break
  }
```
  
  3. If exists, script continues with
  - Shut down AzVM
  - Detach old NIC
  - Attach New Nic
  - Start AzVM

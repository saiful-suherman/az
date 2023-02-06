<#
    This script has been inspired by:

    Charbel Nemnom
    https://charbelnemnom.com/how-to-rename-the-nic-interface-for-an-azure-virtual-machine/
#>

#! Accepted parameters
[CmdletBinding()]
param ($AzSubscription, $RgName, $VmName, $NewNicIpAddress)

#! Check Azure Connection
Connect-AzAccount -Subscription $AzSubscription

#! Get VM Details and store in variable
$Vm = Get-AzVM -Name $VmName

#! Check for existing NIC based on specified IP address, and continue script if EXISTS
$varNewNic = Get-AzNetworkInterface -ResourceGroupName $RgName | Where-Object {$_.IpConfigurations.PrivateIpAddress -eq $newNicIpAddress}

if ($varNewNic -eq $null) {
    Write-Error "`nThe specified new Nic with IP Address $newNicIpAddress does not exist. Exiting Script...`n"
    break
}
else {
    $varNewNicName = $varNewNic.Name
    Write-Host -ForegroundColor Green "The specified new NIC with IP Address $newNicIpAddress exists, and attached to $varNewNicName, continuing script..."
    
    #-! Shutdown VM if 'Running'
        # Check current state
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "`nChecking the Power State of VM '$VmName'..."

        if ((Get-AzVM -Name $Vm.Name -Status).PowerState -eq "VM running")
        {
            Write-Host -ForegroundColor Cyan "`nVM '$VmName' is running..."
            Write-Host -ForegroundColor Cyan "`nStopping and deallocating the VM: '$VmName', please wait..."
        
            # Stop the VM
            Stop-AzVM -Name $Vm.Name -ResourceGroupName $Vm.ResourceGroupName -Force -Confirm:$false
        
            Write-Host -ForegroundColor Green "`nVM '$VmName' is deallocated`n"
        }
        elseif ((Get-AzVM -Name $Vm.Name -Status).PowerState -eq "VM deallocated")
        {
            Write-Host -ForegroundColor Cyan "`nVM '$VmName' is already deallocated continuing script..."
        }
        else
        {
            Write-Host -ForegroundColor Green "`nVirtual Machine '$VmName' is in state: '$varVmPowerState'. Breaking...`n"
            break
        }
    
    #-! Detach the old Network Interface

        # Message that Old NIC will be removed
        $varOldNicId = $Vm.NetworkProfile.NetworkInterfaces.Id
        Write-Host -ForegroundColor Cyan "`nNetwork Interface with following ID will be removed from $VmName :`n$varOldNicId `n"

        Remove-AzVMNetworkInterface -VM $Vm -NetworkInterfaceIDs $varOldNicId

        Write-Host -ForegroundColor Green "`nThe old NIC was removed, but will first be visible once VM is started`n"
        
    #-! Attach the pre-configured Network Interface
    
        # Get Network Interface with Ip Address matching $newNicIpAddress
        $varNewNic = Get-AzNetworkInterface -ResourceGroupName "prod-weu-vnet-001-rg" | Where-Object {$_.IpConfigurations.PrivateIpAddress -eq $newNicIpAddress}

        # Assign variable with value of other variable, for printing to console
        $varNewNicId = $varNewNic.Id

        Write-Host -ForegroundColor Cyan "`nNetwork Interface with following ID will be added to $VmName :`nID: $varNewNicId `nIP Address: $newNicIpAddress`n"

        # Add the network interface
        Add-AzVMNetworkInterface -VM $Vm -Id $varNewNic.Id -Primary

        Write-Host -ForegroundColor Green "`nThe new NIC was added, updating state of VM $VmName with 'Update-AzVM'"

        #Update state of VM
        Update-AzVM -ResourceGroupName $Vm.ResourceGroupName -VM $Vm

    #-! Start VM
        if ((Get-AzVM -Name $VmName -Status).PowerState -ne "VM Running")
        {
            Write-Host -ForegroundColor Cyan "Starting VM: $VmName"

            Start-AzVM -Name $Vm.Name -ResourceGroupName $Vm.ResourceGroupName

            $VmStatus = (Get-AzVM -Name $VmName -Status).Powerstate

            Get-AzVm -Name $Vm.Name
        }
        else
        {
            Write-Host "`nStatus of VM is: $VmStatus`n"
        }
}

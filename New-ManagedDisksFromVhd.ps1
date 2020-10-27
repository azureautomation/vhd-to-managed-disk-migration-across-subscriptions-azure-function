Function New-ManagedDisksFromVhd {
    <#
        .SYNOPSIS
        Function "New-ManagedDisksFromVhd" can be used to create managed disks based on an Azure Virtual Machine backed by Vhd disks.
        Function updated to also perform cross-subscription conversion for Vhd to managed disks (optional).
        
        .DESCRIPTION   
        This function will create managed disks from an Azure Virtual Machine that's backed by Vhd disks.
        The original storage account and Vhd disks will not be removed.
        All criteria of the Vhd disks will be retained, such as:
            -The operating system type (osdisk).
            -The location/region of the managed disk will be the same as the original Vhd (Storage location).
            -The SKU is retained from the original SKU of the storage account the Vhd originated from.
            -The Size of the managed disk will be based on predefined ranges. (e.g. if the original disk size was 100Gb, the new managed disk size will default to 128GB).
            -Created managed disks from Osdisks naming will adopt a naming convention of: "VmName-osdisk"
            -Created managed disks from Datadisks naming will adopt a naming convention of: "VmName-datadisk01", "VmName-datadisk02", "VmName-datadisk03" etc...
        Important functional notes for conversion from Vhd to managed disks across different subscriptions (Also see function examples):
            -If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
            -If the target subscription parameter is used along with the target resource group parameter but the target resource group does not exist, 
             the function will create a new resource group in the target subscription with the value of the target resource group parameter.
            -If only the target subscription parameter is used but NO target resource group parameter was provided, the function will create a new resource group
             in the target subscription with the same value of the source resource group parameter.
        
        .EXAMPLE
        New-ManagedDisksFromVhd -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName Vhdtest -Verbose
                
        All Vhds attached on the VM specified (osdisk and/or datadisks) are converted to managed disks in the same resource group as that of the Vm.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        New-ManagedDisksFromVhd -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName Vhdtest -TargetResourceGroupName newresourcegroup
                
        All Vhds attached on the VM specified (osdisk and/or datadisks) are converted to managed disks and placed in the specified Target Resource Group within the same Subscription.
        If the optional parameter (-TargetResourceGroupName) in this example does not contain a valid target resource group, the disks will be created in the source resource group the Vm resides in (fall back)
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.

        .EXAMPLE
        New-ManagedDisksFromVhd -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName Vhdtest -TargetSubscriptionId yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy -TargetResourceGroupName newrginnewsub -Verbose
                
        All Vhds attached on the VM specified (osdisk and/or datadisks) are converted to managed disks and placed in the specified Target Resource Group within the specified target Subscription.
        If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
        If the target subscription parameter is used along with the target resource group parameter but the target resource group does not exist, the function will create a new resource group in the target subscription with the value of the parameter provided.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        New-ManagedDisksFromVhd -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName Vhdtest -TargetSubscriptionId yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy -Verbose
                
        All Vhds attached on the VM specified (osdisk and/or datadisks) are converted to managed disks and placed in a Target Resource Group named the same as the source resource group within the specified target Subscription.
        If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
        If only the target subscription parameter is used but NO target resource group parameter was provided, the function will create a new resource group in the target subscription with the value of the source resource group.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        $SubId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        $RG = "MyEastUsVms"
        $NewRG = "MyManagedDisks"
        $Vms = "VhdVm1", "VhdVm2", "VhdVm3"
        Foreach ($Vm in $Vms) {
            New-ManagedDisksFromVhd -SubscriptionId $SubId -ResourceGroupName $RG -VmName $Vm -TargetResourceGroupName $NewRG
        }
     
        If any Vms in the array of Vms contain Vhd blobs, managed disks will be created in the target resource group specified: "MyManagedDisks"
        
        .PARAMETER SubscriptionId
        Mandatory Parameter.
        Specify the SubscriptionId containing the source Resource Group and Virtual Machines with Vhd backed storage. <String>
    
        .PARAMETER ResourceGroupName
        Mandatory Parameter.
        Specify the source Resource Group containing the Virtual Machines with Vhd backed storage. <String>
    
        .PARAMETER VmName
        Mandatory Parameter.
        Specify the Virtual Machine names that uses Vhd blobs. <String>

        .PARAMETER TargetSubscriptionId
        Optional Parameter.
        Specify the target Subscription ID where the new managed disks will be created. If this parameter is not specified, the source Subscription ID will be used. <String>
                
        .PARAMETER TargetResourceGroupName
        Optional Parameter.
        Specify the target Resource Group where the new managed disks will be created. If this parameter is not specified, the source Resource Group will be used. <String>
                
        .NOTES
        Author: Paperclips (Pwd9000@hotmail.co.uk)
        PSVersion: 5.1
        Date Created: 29/01/2019
        Updated: 05/02/2019
        Verbose output is displayed using verbose parameter. (-Verbose)
    #>
        
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$SubscriptionId,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$ResourceGroupName,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$VmName,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [String]$TargetSubscriptionId = $SubscriptionId,
        
        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [String]$TargetResourceGroupName = $ResourceGroupName
    )
    
    #Test source subscription and set context.
    If (Get-AzureRmSubscription -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue) {
        $null = Set-AzureRmContext -Subscription $SubscriptionId
    }
    Else {
        Throw "The provided Subscription ID: [$SubscriptionId] could not be found or does not exist. Please provide a valid source Subscription ID."
    }

    #If target subscription provided, test target subscription. (if no target subscription is provided the target subscription will be set the same as the source subscription - See function parameters).
    If ($TargetSubscriptionId) {
        If (-not (Get-AzureRmSubscription -SubscriptionId $TargetSubscriptionId -ErrorAction SilentlyContinue)) {
            Throw "The provided target Subscription ID: [$TargetSubscriptionId] could not be found or does not exist. Please provide a valid target Subscription ID."
        }
    }

    #Test source resource group.
    If (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue) {

        #Test Vm and get Vm object and vhd uris.
        If (Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName -ErrorAction SilentlyContinue) {
            $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName
            $vhdOsDisk = $vm.StorageProfile.OsDisk.vhd.uri
            $vhdDataDisks = $vm.StorageProfile.datadisks.vhd.uri
        }
        Else {
            Throw "The provided Virtual Machine:[$VmName] could not be found or does not exist. Please provide a valid Virtual Machine."
        }
    }
    Else {
        Throw "The provided resource group:[$ResourceGroupName] could not be found or does not exist. Please provide a valid resource group."
    }

    #Get OS disk (VHD) object details and new disk params.
    If ($vhdOsDisk) { 
        $ossourceVhdUri = $vhdOsDisk
        $osType = $vm.StorageProfile.OsDisk.OsType
        $osVhdSize = $vm.StorageProfile.OsDisk.DiskSizeGB
        $osStorageAccountName = ($ossourceVhdUri.Split('/')[2]).split('.')[0]
        $osStorageAccountLocation = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $osStorageAccountName).location
        $osStorageAccountType = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $osStorageAccountName).sku.name
        $osStorageAccountTypePrepend = ([regex]::Match($osStorageAccountType, ".{3}$")).value
        $osStorageAccountTypeAppend = $osStorageAccountType -replace ".{3}$"
        $osSku = $osStorageAccountTypeAppend + "_" + $osStorageAccountTypePrepend
        $osNewDiskName = ($vm.Name) + "-osdisk"
        
        #Resizing logic for new OS disk (Managed).
        $sizeRanges = (1..32) , (33..64) , (65..128) , (129..256) , (257..512) , (513..1024) , (1025..2048)
        Foreach ($sizeRange in $sizeRanges) { 
            If ($osVhdSize -in $sizeRange) { 
                $newOsVhdSize = $sizeRange[-1]
            }    
        }

        #Source and target subscriptions the same.
        If ($SubscriptionId -match $TargetSubscriptionId) {

            #If supplied target resource group not found or not provided, fall back to source resource group.
            If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                Write-Warning "The target resource group:[$TargetResourceGroupName] was not found. [$ResourceGroupName] will be used instead to store new managed disks."
                $TargetResourceGroupName = $ResourceGroupName
            }
            Write-Verbose "Creating Managed Os Disk:[$osNewDiskName] from Vhd blob:[$ossourceVhdUri]"
            Write-Verbose "Managed disk can be found in resource group:[$TargetResourceGroupName]"
            $osDiskConfig = New-AzureRmDiskConfig  -SourceUri $ossourceVhdUri -OsType $osType -Location $osStorageAccountLocation -SkuName $osSku -DiskSizeGB $newOsVhdSize -CreateOption Import
            $null = New-AzureRmDisk -Disk $osDiskConfig -ResourceGroupName $TargetResourceGroupName -DiskName $osNewDiskName    
        }

        #Source and target subscriptions do not match (Cross-subscription).
        Else {
            #Create managed disk in source location of virtual machine (Temporary managed disk).
            $osDiskConfig = New-AzureRmDiskConfig  -SourceUri $ossourceVhdUri -OsType $osType -Location $osStorageAccountLocation -SkuName $osSku -DiskSizeGB $newOsVhdSize -CreateOption Import
            $null = New-AzureRmDisk -Disk $osDiskConfig -ResourceGroupName $ResourceGroupName -DiskName $osNewDiskName
            $osmanagedDisk = Get-AzureRMDisk -ResourceGroupName $ResourceGroupName -DiskName $osNewDiskName

            #Switch to target subscription (Test target subscription performed at beginning of function)
            $null = Set-AzureRmContext -Subscription $TargetSubscriptionId

            #Test target resource group in target subscription.
            #If no target resource group was provided a new resource group will be created in the target subscription with the same name as the source resource group (See function params).
            #Or if a target resource group was provided, but do not exist in the target subscription a new resource group will be created and named as per the provided target resource group parameter.
            If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                Write-Warning "The target Resource Group:[$TargetResourceGroupName] was not found in the target subscription. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                $null = New-AzureRmResourceGroup -Name $targetResourceGroupName -Location $osStorageAccountLocation
            }
            #Create new (copy) disk from source (temporary) managed disk to target subscription and resource group.
            Write-Verbose "Creating Managed Os Disk:[$osNewDiskName] from Vhd blob:[$ossourceVhdUri]"
            Write-Verbose "Managed disk can be found in resource group:[$TargetResourceGroupName]"
            $diskConfig = New-AzureRmDiskConfig -SourceResourceId $osmanagedDisk.Id -Location $osmanagedDisk.Location -CreateOption Copy
            $null = New-AzureRmDisk -Disk $diskConfig -DiskName $osNewDiskName -ResourceGroupName $TargetResourceGroupName

            #Switch back to the source subscription context and clean up the temporary managed disk.
            $null = Set-AzureRmContext -Subscription $SubscriptionId
            $null = Remove-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $osNewDiskName -Force
        }
    }
        
    #Get data disks (VHDs) objects detail and new disks params.
    If ($vhdDataDisks) { 
        $dataDiskConfigs = @()
        Foreach ($i in 0..($vhdDataDisks.count - 1)) {
            $sourceVhdUri = ($vm.StorageProfile.datadisks.vhd.uri)[$i]
            $dataVhdSize = ($vm.StorageProfile.datadisks.DiskSizeGB)[$i]
            $dataStorageAccountName = ($sourceVhdUri.Split('/')[2]).split('.')[0]
            $dataStorageAccountLocation = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $dataStorageAccountName).location
            $dataStorageAccountType = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $dataStorageAccountName).sku.name
            $dataStorageAccountTypePrepend = ([regex]::Match($dataStorageAccountType, ".{3}$")).value
            $dataStorageAccountTypeAppend = $dataStorageAccountType -replace ".{3}$"
            $dataSku = $dataStorageAccountTypeAppend + "_" + $dataStorageAccountTypePrepend
            $newDataDiskName = ($vm.Name) + "-datadisk0" + ($i + 1)
            
            $sizeRanges = (1..32) , (33..64) , (65..128) , (129..256) , (257..512) , (513..1024) , (1025..2048)
            Foreach ($sizeRange in $sizeRanges) { 
                If ($dataVhdSize -in $sizeRange) { 
                    $newDataVhdSize = $sizeRange[-1]
                }    
            }
            $dataDiskConfigs += [pscustomobject]@{URI = $sourceVhdUri; Location = $dataStorageAccountLocation; Sku = $dataSku; Size = $newDataVhdSize; DiskName = $newDataDiskName} 
        }

        Foreach ($dataDiskConfig in $dataDiskConfigs) {
            If ($SubscriptionId -match $TargetSubscriptionId) {
                #If supplied target resource group not found or not passed, fall back to source resource group.
                If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Warning "The target Resource Group:[$TargetResourceGroupName] was not found. [$ResourceGroupName] will be used instead to store new managed disks."
                    $TargetResourceGroupName = $ResourceGroupName
                }
                Write-Verbose "Creating Managed Data Disk:[$($dataDiskConfig.DiskName)] from Vhd blob:[$($dataDiskConfig.URI)]"
                Write-Verbose "Managed disk can be found in Resource Group:[$TargetResourceGroupName]"
                $diskConfig = New-AzureRmDiskConfig  -SourceUri ($dataDiskConfig.URI) -Location ($dataDiskConfig.Location) -SkuName ($dataDiskConfig.Sku) -DiskSizeGB ($dataDiskConfig.Size) -CreateOption Import
                $null = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $TargetResourceGroupName -DiskName ($dataDiskConfig.DiskName)
            }
            Else {
                #Create managed disk in source location of virtual machine (Temporary managed disk).
                $diskConfig = New-AzureRmDiskConfig  -SourceUri ($dataDiskConfig.URI) -Location ($dataDiskConfig.Location) -SkuName ($dataDiskConfig.Sku) -DiskSizeGB ($dataDiskConfig.Size) -CreateOption Import
                $null = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $ResourceGroupName -DiskName ($dataDiskConfig.DiskName)
                $datamanagedDisk = Get-AzureRMDisk -ResourceGroupName $ResourceGroupName -DiskName ($dataDiskConfig.DiskName)

                #Switch to target subscription (Test target subscription performed at beggining of function)
                $null = Set-AzureRmContext -Subscription $TargetSubscriptionId

                #Test target resource group in target subscription.
                #If no target resource group was provided a new resource group will be created in the target subscription with the same name as the source resource group (See function params).
                #Or if a target resource group was provided, but do not exist in the target subscription a new resource group will be created and named as per the provided target resource group parameter.
                If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Warning "The target Resource Group:[$TargetResourceGroupName] was not found in the target subscription. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                    $null = New-AzureRmResourceGroup -Name $targetResourceGroupName -Location ($dataDiskConfig.Location)
                }
                #Create new (copy) disk from source (temporary) managed disk to target subscription and resource group.
                Write-Verbose "Creating Managed Data Disk:[$($dataDiskConfig.DiskName)] from Vhd blob:[$($dataDiskConfig.URI)]"
                Write-Verbose "Managed disk can be found in Resource Group:[$TargetResourceGroupName]"
                $diskConfig = New-AzureRmDiskConfig -SourceResourceId $datamanagedDisk.Id -Location $datamanagedDisk.Location -CreateOption Copy
                $null = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $TargetResourceGroupName -DiskName ($dataDiskConfig.DiskName)

                #Switch back to the source subscription context and clean up the temporary managed disk.
                $null = Set-AzureRmContext -Subscription $SubscriptionId
                $null = Remove-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName ($dataDiskConfig.DiskName) -Force
            }
        }
    }
}
#The following function returns all prices in an object - additional filters can be used: 
#$VMs=Get-AZVMPrices -Location uaenorth -ARCdiscount 10
Function Get-AZVMPrices{    
    Param (
        [parameter()]
        [int]$ARCdiscount=10,
        [parameter()]
        $Location='uaenorth',
        [parameter()]
        $LimitTosubscriptionID,
        [parameter()]
        $IncludeDev=$false,
        [parameter()]
        $login=$false
    )  

    if ($LimitTosubscriptionID){
        write-host "Subscription target= $LimitTosubscriptionID"
        $AvailableSizes=Show-VMsForSubscription -Location $Location -subscriptionID $LimitTosubscriptionID -login $login
        write-host ("Received " + $AvailableSizes.count + " sizes from scubscription in " + $Location + " region")
    }

    $URI="https://prices.azure.com/api/retail/prices?`$filter=armRegionName%20eq%20%27" + $location + "%27%20and%20serviceName%20eq%20%27Virtual%20Machines%27"
    #$location = 'uaenorth'
    #$ARCdiscount=10
    $Objects = New-Object System.Collections.ArrayList

    Write-host "loading prices (each . is 100 items)" -NoNewline
    $InitialCall=Invoke-RestMethod -Uri $URI
    $null=$Objects.Add($InitialCall.Items)

    While ($InitialCall.NextPageLink){
        $InitialCall=Invoke-RestMethod -Uri $InitialCall.NextPageLink
        write-host "." -ForegroundColor Cyan -NoNewline
        $Objects.Add($InitialCall.Items) | out-Null
    }

    ##CLEANUP
    $ObjectsClean = New-Object System.Collections.ArrayList
    ForEach ($array in $Objects) {
        ForEach ($item in $array){
            $null=$ObjectsClean.Add($Item)
        }
    }

    ## FILTERING
    ## If SubscriptionID is used, need to filter ALL vm's by the available VM's for the subscription only:
    
    #ARRAY1 = SubscriptionVM == Name
    #ARRAY2 = ALL VM === armSKUName

    
    #Take Only the Sizes
    If ($LimitTosubscriptionID){
        $VMNames=$AvailableSizes | %{$_.Name}
        $ObjectsClean=$ObjectsClean | Where-Object -FilterScript {$VMNames -contains $_.armSkuName}
    }
    
    ## SORT THEM TO PAYG, 1YR, 3YR
    $VmsPAYG = $ObjectsClean | where {!($_.reservationTerm)}
    $VMs1Yr= $ObjectsClean | where {$_.reservationTerm -eq '1 Year'}
    $VMs3Yr= $ObjectsClean | where {$_.reservationTerm -eq '3 Years'}

    ## CREATE ARRAY FOR PRICES
    [system.collections.arraylist]$outputArray = @()

    $VmsPAYG | ForEach-Object{
        $VmMeter=$_.meterName
        $VMSKU=$_.armSkuName
        $VMs1YrPrice=($VMs1Yr | where {$_.meterName -eq $VmMeter}).retailPrice
        #Fix as some SKU's (DS12, DS13, DS14 are retrieved multiple times - all with same prices)
        If ($VMs1YrPrice -is [array]) {
            $VMs1YrPrice=$VMs1YrPrice[0]
        }
        $VMs3YrPrice=($VMs3Yr | where {$_.meterName -eq $VmMeter}).retailPrice
        If ($VMs3YrPrice -is [array]) {
            $VMs3YrPrice=$VMs3YrPrice[0]
        }

        #PAYGACR is with ACR discount
        If ($ARCdiscount -ne 0) {
            $PAYGACR=[math]::Round((($_.retailPrice-($_.retailPrice * ($ARCdiscount/100)))*730),2)
        }else{
            $PAYGACR=[math]::Round(($_.retailPrice * 730),2)
        }


        $PAYGMonth=[math]::Round(($_.retailPrice*730),2)
        $VM1YRMonth=[math]::Round(($VMs1YrPrice/12),2)
        $VM3YRMonth=[math]::Round(($VMs3YrPrice/36),2)

        If ($_.type -eq 'DevTestConsumption') {
            $DEV = 'DEV'
        }else{
            $DEV='PROD'
        }

        #1YR Percentage
        $1YrPercentage=[math]::Round((($VM1YRMonth/$PAYGACR)*100),0)
        $3YrPercentage=[math]::Round((($VM3YRMonth/$PAYGACR)*100),0)

        #If Subscription - we want to add CPU/Memory
        If ($LimitTosubscriptionID){
            $Cores=($AvailableSizes | where {$_.Name -eq $VMSKU}).NumberOfCores
            $MEMGB=(($AvailableSizes | where {$_.Name -eq $VMSKU}).MemoryInMB)/1024
            $_ | Add-Member -MemberType NoteProperty -Name "Cores" -Value $Cores -Force
            $_ | Add-Member -MemberType NoteProperty -Name "Memory" -Value $MEMGB -Force    
        }

        $_ | Add-Member -MemberType NoteProperty -Name "PAYG" -Value $PAYGMonth -Force
        $_ | Add-Member -MemberType NoteProperty -Name "Discount" -Value $ARCdiscount -Force
        $_ | Add-Member -MemberType NoteProperty -Name "DACR" -Value $PAYGACR -Force
        $_ | Add-Member -MemberType NoteProperty -Name "1YR" -Value $VM1YRMonth -Force
        $_ | Add-Member -MemberType NoteProperty -Name "3YR" -Value $VM3YRMonth -Force
        $_ | Add-Member -MemberType NoteProperty -Name "1Y%" -Value $1YrPercentage -Force
        $_ | Add-Member -MemberType NoteProperty -Name "3Y%" -Value $3YrPercentage -Force
        

    }
    #write-host "example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT"
    #write-host "example: $yourVariable | where {$_.Cores -eq 4} | ft"
    If (!($IncludeDev)){
        $VmsPAYG=$VmsPAYG|where {$_.type -ne 'DevTestConsumption'}
    }
    write-host '$yourVariable=Get-AZVMPrices -ARCdiscount 10 -Location uaenorth' -ForegroundColor Cyan
    write-host 'then adjust the output as needed for $MyItems array' -ForegroundColor Cyan
    write-host 'example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT' -ForegroundColor Yellow
    write-host 'example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |Export-CSV c:\myprices.csv' -ForegroundColor Yellow
    write-host 'example: $yourVariable | where {$_.Cores -eq 4} | ft' -ForegroundColor Yellow
    return $VmsPAYG
}

Function Show-VMsForSubscription {
    Param (
        [parameter()]
        $login=$false,
        [parameter()]
        $Location='uaenorth',
        [parameter()]
        $subscriptionID
    ) 

    If ($login){
        If (!((Get-Module -ListAvailable) -match 'Az.Compute')) {
            write-host "no AZ modules found"
            exit
        }
        Connect-AzAccount -subscriptionID $subscriptionID
    }
    $context=Get-AzContext
    if ($context.subscription.ID -ne $subscriptionID){
        Set-AZContext -subscriptionid -$subscriptionID
    }
    write-host "retrieving subscription based sizes"
    $AvailableSizes=Get-AZVMSize -location $location
    return $AvailableSizes
}

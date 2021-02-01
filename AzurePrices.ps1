Param (
    [parameter()]
    [int]$ARCdiscount=0,
    [parameter()]
    $Location='uaenorth',
    [parameter()]
    $LimitTosubscriptionID,
    [parameter()]
    $IncludeDev=$false,
    [parameter()]
    $login=$false,
    [parameter()]
    $cores,
    [parameter()]
    $memory
)  

#Cosmetic stuff
write-host ""
write-host ""
write-host "                               _____        __                                " -ForegroundColor Green
write-host "     /\                       |_   _|      / _|                               " -ForegroundColor Yellow
write-host "    /  \    _____   _ _ __ ___  | |  _ __ | |_ _ __ __ _   ___ ___  _ __ ___  " -ForegroundColor Red
write-host "   / /\ \  |_  / | | | '__/ _ \ | | | '_ \|  _| '__/ _' | / __/ _ \| '_ ' _ \ " -ForegroundColor Cyan
write-host "  / ____ \  / /| |_| | | |  __/_| |_| | | | | | | | (_| || (_| (_) | | | | | |" -ForegroundColor DarkCyan
write-host " /_/    \_\/___|\__,_|_|  \___|_____|_| |_|_| |_|  \__,_(_)___\___/|_| |_| |_|" -ForegroundColor Magenta
write-host "     "
write-host "This script provides you with an overview of prices for Azure VM's in region $location" -ForegroundColor Green
write-host "option are: "
write-host " -ARCdiscount - the discount in % for your subscription"
write-host " -location - the location short code (uaenorth, westeurope, northeurope, etc)"
write-host " -limitToSubscriptionID abd678-def98-987678-976 - limits the output to sizes only available in the subscription (required login)"
write-host " -IncludeDev - includes VM's available in Dev/Test subscriptions SKU's"
write-host " -Login - true or false to force Az logins"
write-host 
write-host "The script can also output % of RI's compared to PAYG (with ACR discount included) - that way you can determine when to use an RI"
write-host "for example:"
write-host "meterName                   productName                           Cores Memory   PAYG   DACR    1YR 1Y%    3YR 3Y%"
write-host "---------                   -----------                           ----- ------   ----   ----    --- ---    --- ---"
write-host "D4s v4                      Virtual Machines Dsv4 Series Windows      4     16 319.01 287.11 109.17  38 287.11  24"
write-host ""
write-host "PAYG pricing is retail pricing"
write-host "DACR is the PAYG pricing with discount on it"
write-host "the 38% for the 1YR RI indicates that if the VM will be used >38% of the time (in 1 year), an RI will be cheaper than DACR"
write-host "the 24% for the 3YR RI indicates that if the VM will be used >24% of the time (in 3 years), an RI will be cheaper than DACR"
write-host ""
Write-host "You can also use the module separately if you need to adjust the output - import the AzurePrices.psm1 module and run" -ForegroundColor Cyan
write-host '$yourVariable=Get-AZVMPrices -ARCdiscount 10 -Location uaenorth' -ForegroundColor Cyan
write-host 'then adjust the output as needed for $MyItems array' -ForegroundColor Cyan
write-host 'example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT' -ForegroundColor Yellow
write-host 'example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |Export-CSV c:\myprices.csv' -ForegroundColor Yellow
write-host 'example: $yourVariable | where {$_.Cores -eq 4} | ft' -ForegroundColor Yellow

If ((Get-Module) -match "AzurePrices"){
    write-host "refreshing module" -ForegroundColor Cyan
    remove-module AzurePrices
}
Import-Module .\AzurePrices.psm1

write-host 
write-host 

If (!($LimitTosubscriptionID)){
    write-host 'Full list of VMs without limits'
    $FullArray=Get-AZVMPrices -ARCdiscount $ARCdiscount -Location $location -IncludeDev $IncludeDev -login $login
}else {
    write-host 'Full list of VMs with subscription - adds cores and memory'
    $FullArray=Get-AZVMPrices -ARCdiscount $ARCdiscount -Location $location -IncludeDev $IncludeDev -login $login -limitToSubscriptionID $LimitTosubscriptionID
}

If (!($cores) -or !($memory)) {
    write-host 'Full list of VMs'
    $FullArray | select meterName, productName, Cores, Memory, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT
}elseif ($cores -and !($memory)) {
    write-host "VMs with $cores cores"
    $FullArray | where {$_.cores -eq $cores} | select meterName, productName, Cores, Memory, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT
}elseif (!($cores) -and $memory) {
    write-host "VMs with $memory GB memory"
    $FullArray | where {$_.memory -eq $memory} | select meterName, productName, Cores, Memory, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT
}else {
    write-host "VMs with $cores cores or $memory GB memory"
    $FullArray | where {$_.memory -eq $memory -or $_.cores -eq $cores} | select meterName, productName, Cores, Memory, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT
}


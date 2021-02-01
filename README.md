# AzurePrices

This script provides you with an overview of prices for Azure VM's in region uaenorth
option are:
 -ARCdiscount - the discount in % for your subscription
 -location - the location short code (uaenorth, westeurope, northeurope, etc)
 -limitToSubscriptionID abd678-def98-987678-976 - limits the output to sizes only available in the subscription (required login)
 -IncludeDev - includes VM's available in Dev/Test subscriptions SKU's
 -Login - true or false to force Az logins

The script can also output % of RI's compared to PAYG (with ACR discount included) - that way you can determine when to use an RI
for example:
meterName                   productName                           Cores Memory   PAYG   DACR    1YR 1Y%    3YR 3Y%
---------                   -----------                           ----- ------   ----   ----    --- ---    --- ---
D4s v4                      Virtual Machines Dsv4 Series Windows      4     16 319.01 287.11 109.17  38 287.11  24

PAYG pricing is retail pricing
DACR is the PAYG pricing with discount on it
the 38% for the 1YR RI indicates that if the VM will be used >38% of the time (in 1 year), an RI will be cheaper than DACR
the 24% for the 3YR RI indicates that if the VM will be used >24% of the time (in 3 years), an RI will be cheaper than DACR

You can also use the module separately if you need to adjust the output - import the AzurePrices.psm1 module and run
$MyItems=Get-AZVMPrices -ARCdiscount 10 -Location uaenorth
then adjust the output as needed for $MyItems array
example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |FT
example: $yourVariable | select meterName, productName, PAYG, DACR, 1YR, 1Y%, 3YR, 3Y% | sort-object -property meterName |Export-CSV c:\myprices.csv
example: $yourVariable | where {$_.Cores -eq 4} | ft

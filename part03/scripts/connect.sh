#!/bin/bash

target=$1

ip=$(az network public-ip show \
    --ids "$(az network nic list \
        --resource-group rg-nomad-on-azure \
        --query "[?starts_with(name, 'nic-$target')] | [0].ipConfigurations[0].publicIPAddress.id" \
        -o tsv)" \
    --query "ipAddress" --output tsv)

ssh -i ssh_keys/servers.pem azureuser@$ip
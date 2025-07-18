#!/bin/bash

resourceGroup="rg-consul-on-azure"

az network nic list \
    --resource-group "$resourceGroup" \
    --query "[?starts_with(name, 'nic-consul-servers')].{name:name}" -o tsv | \
while read -r nicName; do
    az network nic update \
        --name "$nicName" \
        --resource-group "$resourceGroup" \
        --set tags.consul="server" \
        --no-wait
done
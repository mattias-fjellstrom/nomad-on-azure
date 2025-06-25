#!/bin/bash

resourceGroup="rg-nomad-on-azure"

az network nic list \
    --resource-group "$resourceGroup" \
    --query "[].{name:name}" -o tsv | \
while read -r nicName; do
    az network nic update \
        --name "$nicName" \
        --resource-group "$resourceGroup" \
        --set tags.nomad="server"
done
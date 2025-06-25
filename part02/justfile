tag:
    #!/bin/bash
    # list all Azure VMs with a given tag. Then, for each VM get the attached NICs. Then apply a tag to each NIC.
    az vm list --query "[?tags.consul=='server'].{name:name, resourceGroup:resourceGroup, id:id}" -o tsv | while read -r name resourceGroup id; do
        _id=$(echo "$id" | tr '[:upper:]' '[:lower:]')
        _resourceGroup=$(echo "$resourceGroup" | tr '[:upper:]' '[:lower:]')
        echo "Processing VM: $name in Resource Group: $_resourceGroup"
        
        echo "VM ID: $_id"
        az network nic list --resource-group "$_resourceGroup" --query "[?virtualMachine.id=='$_id'].{name:name}" -o tsv | while read -r nicName; do
            echo "Tagging NIC: $nicName"
            az network nic update --name "$nicName" -g "$_resourceGroup" --set tags.consul="server"
        done
    done
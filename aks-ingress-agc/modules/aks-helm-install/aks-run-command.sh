#!/bin/bash

set -e +H
# -e to exit on error
# +H to prevent history expansion

# Set the script's locale to UTF-8 to ensure proper handling of UTF-8 encoded text
export LANG=C.UTF-8

if [ "$initialDelay" != "0" ]
then
    echo "Waiting on RBAC replication ($initialDelay)"
    sleep "$initialDelay"

    #Force RBAC refresh
    az logout
    az login --identity
fi

echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut="$(az aks command invoke -g "$RG" -n "$aksName"  --command "helm upgrade --install ${helmApp} ${helmOciURL} ${helmAppParams}")"
echo "$cmdOut"

jsonOutputString=$(jq -n --arg output "$cmdOut" '{output: $output}')
echo "$jsonOutputString" > "$AZ_SCRIPTS_OUTPUT_PATH"

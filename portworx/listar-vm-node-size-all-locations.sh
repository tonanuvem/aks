#!/bin/sh

CPU_COUNT=1
MEMORY_GB=8

for region in $(az account list-locations --query "[].name" -o tsv); do
  echo "Região: $region"

  az vm list-skus \
    --location $region \
    --size Standard_B* \
    --query "[?capabilities[?name=='vCPUs' && value=='$CPU_COUNT'] && capabilities[?name=='MemoryGB' && value > \`$MEMORY_GB\`]].name" \
    -o tsv

  echo ""
done

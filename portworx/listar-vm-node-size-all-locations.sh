#!/bin/sh

CPU_COUNT=1
MEMORY_GB=8
OUTPUT_FILE="node-vms-list.txt"

# Limpa o arquivo antes de começar
> $OUTPUT_FILE

for region in $(az account list-locations --query "[].name" -o tsv); do
  echo "Região: $region" >> $OUTPUT_FILE

  az vm list-skus \
    --location $region \
    --size Standard_B* \
    --query "[?capabilities[?name=='vCPUs' && value=='$CPU_COUNT'] && capabilities[?name=='MemoryGB' && value > \`$MEMORY_GB\`]].name" \
    -o tsv >> $OUTPUT_FILE

  echo "" >> $OUTPUT_FILE
done

#!/bin/bash

# Source the common file containing REPO_MAP
source ./setup.rc

# Export repositories using the REPO_MAP
for repo_name in "${!REPO_MAP[@]}"; do
    product_name="${REPO_MAP[$repo_name]}"  
    echo "Exporting repository: $repo_name"
    
    # Use hammer to export repository in syncable format
    hammer content-export complete repository \
        --organization="$ORG" \
        --chunk-size-gb="$chunk_size_gb" \
        --format syncable \
        --product "$product_name" \
        --name "$repo_name"
done

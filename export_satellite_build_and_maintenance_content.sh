#!/bin/bash

# Source the common file containing REPO_MAP
source ./setup.rc

# Validate that required variables are defined and have values
local missing_vars=()

# Check for required variables that must be defined after sourcing setup.rc
local required_vars=("ORG" "CHUNK_SIZE_GB" "REPO_MAP")

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

# Check if any variables are missing
if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "Error: The following variables are not defined or have empty values:" >&2
    for var in "${missing_vars[@]}"; do
        echo "  $var" >&2
    done
    echo "Please check your setup.rc file and ensure all required variables are defined." >&2
    exit 1
fi

# Validate that REPO_MAP is not empty
if [[ ${#REPO_MAP[@]} -eq 0 ]]; then
    echo "Error: REPO_MAP is empty. No repositories to export." >&2
    exit 1
fi

# --- MAIN ---
# Export repositories using the REPO_MAP
for repo_name in "${!REPO_MAP[@]}"; do
    product_name="${REPO_MAP[$repo_name]}"  
    echo "Exporting repository: $repo_name"
    
    # Use hammer to export repository in syncable format
    hammer content-export complete repository \
        --organization="$ORG" \
        --chunk-size-gb="$CHUNK_SIZE_GB" \
        --format syncable \
        --product "$product_name" \
        --name "$repo_name"
done

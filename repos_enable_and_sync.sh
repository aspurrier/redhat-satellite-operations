#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e


# Ensure this file exists and contains the REPO_MAP associative array
source ./setup.rc

local missing_vars=()

# Check for required variables that must be defined after sourcing setup.rc
local required_vars=("ORG" "PLAN_NAME" "REPO_MAP" "REPO_SET_LIST")

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
    echo "Error: REPO_MAP is empty. No repositories to process." >&2
    exit 1
fi

# Validate that REPO_SET_LIST is not empty
if [[ ${#REPO_SET_LIST[@]} -eq 0 ]]; then
    echo "Error: REPO_SET_LIST is empty. No repository sets to process." >&2
    exit 1
fi


echo "Checking Satellite State for Organization: $ORG"
echo "------------------------------------------------"

for REPO_SET_NAME in "${REPO_SET_LIST[@]}"; do
    IS_ENABLED=$(hammer --csv --no-headers repository-set list --organization "$ORG" --enabled true --name "$REPO_SET_NAME" 2>/dev/null || true)
    if [ -z "$IS_ENABLED" ]; then
        echo "[ACTION] Enabling the repository-set '$REPO_SET_NAME'..."
        if [[ "$REPO_SET_NAME" == *"Enterprise Linux 9"* ]]; then
            hammer repository-set enable --organization "$ORG" --basearch "x86_64" --releasever "9" --name "$REPO_SET_NAME"
        else
            hammer repository-set enable --organization "$ORG" --basearch "x86_64" --name "$REPO_SET_NAME"
        fi
    else
        echo "[SKIP] $REPO_SET_NAME is already enabled."
    fi
done


for REPO_NAME in "${!REPO_MAP[@]}"; do
    PRODUCT_NAME="${REPO_MAP[$REPO_NAME]}"
    
    # Fetch policy using the new name-based logic
    CURRENT_POLICY=$(hammer --csv --no-headers repository info --organization="$ORG" --product="$PRODUCT_NAME" --name="$REPO_NAME" --fields="Download Policy")
    
    if [ "$CURRENT_POLICY" != "immediate" ]; then
        echo "[ACTION] Setting Download Policy to 'immediate' for $REPO_NAME..."
        hammer repository update --organization "$ORG" --product "$PRODUCT_NAME" --name "$REPO_NAME" --download-policy immediate
    else
        echo "[SKIP] Download Policy for $REPO_NAME is already 'immediate'."
    fi
done

# 2. Idempotent Sync Plan Creation
PLAN_EXISTS=$(hammer --csv --no-headers sync-plan list --organization "$ORG" --search "name = $PLAN_NAME")

if [ -z "$PLAN_EXISTS" ]; then
    echo "[ACTION] Creating Sync Plan: $PLAN_NAME..."
    hammer sync-plan create \
      --name "$PLAN_NAME" \
      --organization "$ORG" \
      --interval "custom cron" \
      --cron-expression "0 2 * * 1-5" \
      --sync-date "$(date +%Y-%m-%d) 02:00:00" \
      --enabled true
else
    echo "[SKIP] Sync Plan '$PLAN_NAME' already exists."
fi

# 3. Product Association (Derived from REPO_MAP)
echo -e "\nVerifying Product Associations..."
declare -A UNIQUE_PRODUCTS

# Derive unique product names from the REPO_MAP values
for prod in "${REPO_MAP[@]}"; do
    UNIQUE_PRODUCTS["$prod"]=1
done

for PRODUCT_NAME in "${!UNIQUE_PRODUCTS[@]}"; do
    # Check if product is already assigned to the plan
    ASSIGNED_PLAN=$(hammer --csv --no-headers product info --organization "$ORG" --name "$PRODUCT_NAME" --fields="Sync Plan ID")
    
    if [ -z "$ASSIGNED_PLAN" ]; then
        echo "[ACTION] Assigning Product '$PRODUCT_NAME' to Sync Plan '$PLAN_NAME'..."
        hammer product update --name "$PRODUCT_NAME" --organization "$ORG" --sync-plan "$PLAN_NAME"
    else
        echo "[SKIP] Product '$PRODUCT_NAME' is already assigned to the correct plan."
    fi
    echo "[ACTION] Initializing manual sync for Product: $PRODUCT_NAME..."
    hammer product synchronize --name "$PRODUCT_NAME" --organization "$ORG" --async
done

echo -e "\n------------------------------------------------"
echo "All tasks submitted. Background sync tasks have been started for all relevant products."

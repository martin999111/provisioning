#!/bin/bash

# --- Configuration ---
CIVITAI_API_KEY="YOUR_API_KEY_HERE" # Replace with your actual API Key
MODEL_ID=""                  # The Model ID you provided

# --- Validate API Key and Model ID ---
if [[ "$CIVITAI_API_KEY" == "YOUR_API_KEY_HERE" || "$MODEL_ID" == "YOUR_MODEL_ID_HERE" ]]; then
    echo "Error: Please replace 'YOUR_API_KEY_HERE' and 'YOUR_MODEL_ID_HERE' with actual values in the script."
    exit 1
fi

echo "Fetching model details for Model ID: ${MODEL_ID}..."

# --- Step 1: Fetch model details using curl and Civitai API ---
MODEL_DETAILS=$(curl -s -H "Authorization: Bearer ${CIVITAI_API_KEY}" "https://civitai.com/api/v1/models/${MODEL_ID}")

# --- Robust Error Checking before JQ ---
if [ -z "$MODEL_DETAILS" ]; then
    echo "Error: curl returned an empty response. Check network connection or Civitai server status."
    exit 1
fi

if echo "$MODEL_DETAILS" | jq -e 'has("error")' > /dev/null; then
    echo "Civitai API returned an error:"
    echo "$MODEL_DETAILS" | jq . # Pretty print the error
    echo "Possible causes: Invalid API Key, Model ID not found, or other API issues."
    exit 1
fi

if ! echo "$MODEL_DETAILS" | jq -e 'has("modelVersions") and (.modelVersions | length > 0)' > /dev/null; then
    echo "Error: Model JSON structure unexpected or no 'modelVersions' found for Model ID ${MODEL_ID}."
    echo "Full API Response received:"
    echo "$MODEL_DETAILS" | jq . # Pretty print the full response
    exit 1
fi

echo "Model details fetched successfully. Attempting to locate download file."

# --- Step 2: Extract the download URL and filename using jq ---
DOWNLOAD_INFO=$(echo "${MODEL_DETAILS}" | jq -r '
  .modelVersions[0] // null |                 # Get the first model version (latest), or null
  .files // [] |                             # Get all files from that version, or empty array if none
  map(select(.type == "Model")) |            # Filter for files of type "Model"
  .[0] // null |                             # Get the first (best-matched) file, or null if no Model type file
  {url: .downloadUrl, name: .name}           # Extract .downloadUrl and .name
')

# Check if JQ found a suitable file
if [ -z "$DOWNLOAD_INFO" ] || [ "$DOWNLOAD_INFO" = "null" ]; then
    echo "Error: Could not find a suitable 'Model' file in the latest version for model ID ${MODEL_ID}."
    echo "Please verify the model ID, file type, or adjust the jq filter if you're looking for something else (e.g., specific LoRA or VAE)."
    echo "Full API Response for debugging:"
    echo "$MODEL_DETAILS" | jq .
    exit 1
fi

DOWNLOAD_URL=$(echo "$DOWNLOAD_INFO" | jq -r '.url')
OUTPUT_FILENAME=$(echo "$DOWNLOAD_INFO" | jq -r '.name')

if [ -z "$DOWNLOAD_URL" ] || [ -z "$OUTPUT_FILENAME" ]; then
    echo "Error: JQ extracted null URL or filename. This might indicate an issue with the JSON extraction logic."
    echo "DOWNLOAD_INFO: $DOWNLOAD_INFO"
    exit 1
fi

echo "Found download URL: ${DOWNLOAD_URL}"
echo "Downloading to: ${OUTPUT_FILENAME}"

# --- Step 3: Use curl to download the file ---
# CRITICAL CHANGE: Using curl for download
curl -L \
  -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
  "$DOWNLOAD_URL" \
  -o "$OUTPUT_FILENAME"

# Check curl's exit status
if [ $? -ne 0 ]; then
    echo "Error: curl download failed."
    exit 1
fi

echo "Download complete."

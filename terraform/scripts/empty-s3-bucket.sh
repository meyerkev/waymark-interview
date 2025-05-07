#!/bin/bash
set -euo pipefail

BUCKET="$1"

if [[ -z "$BUCKET" ]]; then
  echo "Usage: $0 <bucket-name>"
  exit 1
fi

echo "Emptying bucket: $BUCKET..."

# Get object versions
aws s3api list-object-versions --bucket "$BUCKET" --output json > objects.json

jq -c '.Versions[]?' objects.json | while read -r obj; do
  key=$(echo "$obj" | jq -r '.Key')
  version=$(echo "$obj" | jq -r '.VersionId')
  echo "Deleting object version: $key (version: $version)"
  aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version"
done

jq -c '.DeleteMarkers[]?' objects.json | while read -r obj; do
  key=$(echo "$obj" | jq -r '.Key')
  version=$(echo "$obj" | jq -r '.VersionId')
  echo "Deleting delete marker: $key (version: $version)"
  aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version"
done

rm -f objects.json

echo "Done."

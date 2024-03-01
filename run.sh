#!/bin/bash

BUCKET_NAME="${BUCKET_NAME}"
NUM_VERSIONS_TO_KEEP="${NUM_VERSIONS_TO_KEEP:-10}"
FILENAME="${FILENAME:-backup}"
DATABASE="${DATABASE}"
PREFIX="mongo-backups/${DATABASE}/"

required_vars=("DATABASE" "MONGO_URI" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_ENDPOINT_URL" "S3CMD_ENDPOINT_URL" "BUCKET_NAME")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var environment variable is not set. Exiting..."
    exit 1
  fi
done

# Remove leading slash if present in PREFIX
PREFIX=$(echo "$PREFIX" | sed "s/^\///" )

# Configure s3cmd
{
  echo "host_base = $S3CMD_ENDPOINT_URL"
  echo "access_key = $AWS_ACCESS_KEY_ID"
  echo "secret_key = $AWS_SECRET_ACCESS_KEY"
  echo "host_bucket = %(bucket)s.$S3CMD_ENDPOINT_URL"
  echo "bucket_location = US"
} > ~/.s3cfg

now=$(date "+%Y%m%d%H%M%S")

file_ext="gz"

echo "Backing up MongoDB database '$database' and uploading to ${bucket_name}/${prefix}${now}-${filename}.${file_ext}"

mongodump --uri="$MONGO_URI" --db="$database" --archive | gzip \
  | s3cmd put - "s3://${bucket_name}/${prefix}${now}-${filename}.${file_ext}"

# Exit if no backup rotation is required
if [ "$num_versions_to_keep" -eq 0 ]; then
  exit 0
fi

# List all files in the backup directory
files=$(aws s3api list-objects --bucket "$bucket_name" \
  --prefix "$prefix" \
  --query 'Contents[].{Key: Key}' \
  --output text)

echo "$files"

echo "Removing older versions (if any)..."

echo "$files" \
  | grep -oP "^${prefix}[0-9]{14}-${filename}\.${file_ext}$" \
  | sort -r \
  | tail -n "+$((${num_versions_to_keep} + 1))" \
  | xargs -I {} aws s3 rm "s3://${bucket_name}/{}"
  
echo "Backup rotation complete"

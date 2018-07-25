#!/bin/bash
set -eu -o pipefail

[[ $# -lt 2 ]] && {
    echo "Usage $0 <BUILD_SLUG> <CATS_AZ>" >&2
    echo "  Example: $0 bucket-foo/randomid us-east-1" >&2
    exit 1
}

# Required vars
BUILD_SLUG=$1
CATS_AZ=$2

# Internal vars
AWS_AZ=$(curl -sSL http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_DOMAIN=$(curl -sSL http://169.254.169.254/latest/meta-data/services/domain)
SALT_SLUG="${BUILD_SLUG}/salt"
STATIC_SLUG="${BUILD_SLUG}/static"
BASE_URL="https://s3.${AWS_DOMAIN}/${STATIC_SLUG}"

# Export standard aws envs
export AWS_DEFAULT_REGION=${AWS_AZ:0:${#AWS_AZ} - 1}

echo "[appscript]: Ensuring default salt srv location exists, /srv/salt..."
mkdir -p /srv/salt

echo "[appscript]: Syncing salt content from s3://${SALT_SLUG}..."
aws s3 sync --delete "s3://${SALT_SLUG}" /srv/salt

echo "[appscript]: Updating salt grains..."
salt-call --local saltutil.sync_grains

echo "[appscript]: Configuring salt to read ec2 metadata into grains..."
echo "metadata_server_grains: True" > /etc/salt/minion.d/metadata.conf

echo "[appscript]: Setting required salt grains..."
salt-call --local grains.set cats-or-dogs "{'base_url':'${BASE_URL}', 'cats_az':'${CATS_AZ}'}" force=True

echo "[appscript]: Applying the cats-or-dogs state..."
salt-call --local --retcode-passthrough state.sls cats-or-dogs

echo "[appscript]: Completed cats-or-dogs appscript successfully!"

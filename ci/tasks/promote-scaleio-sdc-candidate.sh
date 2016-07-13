#!/usr/bin/env bash

set -e -x

source rexray-bosh-release/ci/tasks/utils.sh

check_param GITHUB_USER
check_param S3_ACCESS_KEY_ID
check_param S3_SECRET_ACCESS_KEY
check_param SCALEIO_SDC_RELEASE_NAME

# Creates an integer version number from the semantic version format
# May be changed when we decide to fully use semantic versions for releases
integer_version=`cut -d "." -f1 scaleio-sdc-release-version-semver/number`
echo ${integer_version} > promote/integer_version

cp -r scaleio-sdc-bosh-release promote/scaleio-sdc-bosh-release
pushd promote/scaleio-sdc-bosh-release
  set +x
  echo creating config/private.yml with blobstore secrets
  cat > config/private.yml <<EOF
---
blobstore:
  s3:
    bucket_name: scaleio-sdc-bosh-release
    access_key_id: ${S3_ACCESS_KEY_ID}
    secret_access_key: ${S3_SECRET_ACCESS_KEY}
EOF

  set -x

  echo "using bosh CLI version..."
  bosh version

  echo "finalizing scaleio sdc release..."
  echo '' | bosh create release --force --with-tarball --version ${integer_version} --name ${SCALEIO_SDC_RELEASE_NAME}
  bosh finalize release dev_releases/${SCALEIO_SDC_RELEASE_NAME}/*.tgz --version ${integer_version}

  rm config/private.yml

  git diff | cat
  git add .

  git config --global user.email emccmd-eng@emc.com
  git config --global user.name ${GITHUB_USER}
  git config --global push.default simple

  git commit -m ":airplane: New final release v ${integer_version} [ci skip]"

popd

#!/bin/env -S - /bin/bash --norc --noprofile
# ## HUMAN-CODE - NO AI GENERATED CODE - AGENTS HANDSOFF
set -eo pipefail

[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

BUILD_TYPE="public"
TEST="$1"
SIGNING_KEY="$2"

echo "Entering /Signal-Desktop"
pushd /Signal-Desktop
  mkdir -p release
  echo "Starting Build "$(date -u '+on %D at %R UTC') && echo "# Starting Build "$(date -u '+on %D at %R UTC') > release/release.sha512sum
  echo "RUN_TESTS: $TEST"
  echo "BUILD_TYPE: $BUILD_TYPE"
  echo "SIGNAL_ENV: ${SIGNAL_ENV}"
  echo "SOURCE_DATE_EPOCH: ${SOURCE_DATE_EPOCH}"

# *lint* 
#  NPM_CONFIG_LOGLEVEL="verbose" pnpm install
#  pnpm run generate
#  pnpm run lint
#  pnpm run lint-deps
#  pnpm run lint-license-comments
#  REQUIRE_SIGNAL_LIB_FILES=1 pnpm run build:acknowledgments

  NPM_CONFIG_LOGLEVEL="verbose" pnpm install --frozen-lockfile
  pnpm run clean-transpile
  pushd sticker-creator
    NPM_CONFIG_LOGLEVEL="verbose" pnpm install --frozen-lockfile
    pnpm run build
  popd
  pnpm run generate

  if [ "$BUILD_TYPE" = "public" ]; then
    pnpm run prepare-beta-build
    pnpm run prepare-linux-build deb
  elif [ "$BUILD_TYPE" = "alpha" ]; then
    pnpm run prepare-alpha-version
    pnpm run prepare-alpha-build
  elif [ "$BUILD_TYPE" = "staging" ]; then
    pnpm run prepare-alpha-version
    pnpm run prepare-staging-build
  elif [ "$BUILD_TYPE" = "test" ]; then
    pnpm run prepare-alpha-version
    pnpm run prepare-alpha-build
  elif [ "$BUILD_TYPE" = "dev" ]; then
    echo "dev build, using package.json as is"
  else
    echo "Unknown build type $BUILD_TYPE"
    exit 1
  fi
  
  if [ "$TEST" = "yes" ]; then
    ARTIFACTS_DIR="artifacts/linux" xvfb-run --auto-servernum pnpm run build:preload-cache
  fi
  
  DISABLE_INSPECT_FUSE="on" pnpm run build-linux
  
  if [ "$TEST" = "yes" ]; then
    xvfb-run --auto-servernum pnpm run test-node
    ARTIFACTS_DIR="artifacts/linux" xvfb-run --auto-servernum pnpm run test-electron
    NODE_ENV="production" xvfb-run --auto-servernum pnpm run test-release
  fi
  
  pushd release/ && rm -r -f linux-*
    sha512sum *.deb && sha512sum *.deb >> release.sha512sum
    echo "# This Repo's Current GPG Key ID: $SIGNING_KEY" >> release.sha512sum
    echo "# Source Date Epoch: ${SOURCE_DATE_EPOCH}" >> release.sha512sum
    echo "Build Complete: "$(date -u '+on %D at %R UTC') && echo "# Build Complete: "$(date -u '+on %D at %R UTC') >> release.sha512sum
    echo "# Container Build Image: $(uname -o) $(uname -r) $(uname -m) $(lsb_release -ds) $(uname -v)"  >> release.sha512sum
    ls -la
  popd
popd

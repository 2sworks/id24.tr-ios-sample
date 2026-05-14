#!/bin/zsh
#  ci_post_xcodebuild.sh

chmod +x /Volumes/workspace/repository/ci_scripts/ci_post_xcodebuild.sh

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  
  mkdir -p $TESTFLIGHT_DIR_PATH
  
  git fetch --tags --unshallow || git fetch --tags
  
  # Get latest commit message and description
  git log -1 --pretty=format:"%s%n%n%b" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  
  if [[ ! -f "$TESTFLIGHT_DIR_PATH/WhatToTest.tr-TR.txt" ]]; then
      exit 1
  fi
fi

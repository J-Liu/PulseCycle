#!/bin/bash

xcodebuild -project PulseCycle.xcodeproj \
  -scheme PulseCycle \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  build

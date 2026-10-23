#!/bin/bash

xcodebuild -project PulseCycle.xcodeproj \
  -scheme PulseCycle \
  -destination 'platform=iOS,name=iPhone' \
  -allowProvisioningUpdates \
  build

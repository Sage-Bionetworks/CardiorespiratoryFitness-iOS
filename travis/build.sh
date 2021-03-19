#!/bin/sh
set -ex
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then     # on pull requests
    echo "Build on PR"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test scheme:"CRFSampleApp"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" == "main" ]]; then  # non-tag commits to main branch
    echo "Build on merge to main"
    git clone https://github.com/Sage-Bionetworks/iOSPrivateProjectInfo.git ../iOSPrivateProjectInfo
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test scheme:"CRFSampleApp"
    bundle exec fastlane keychains
    bundle exec fastlane certificates
    # bundle exec fastlane ci_archive scheme:"CRFSampleApp" export_method:"app-store"
    bundle exec fastlane ci_archive scheme:"CRFHeartRate" export_method:"app-store" project:"CRFHeartRate/CRFHeartRate.xcodeproj"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" =~ ^stable-.* ]]; then # non-tag commits to stable branches
    echo "Build on stable branch"
    git clone https://github.com/Sage-Bionetworks/iOSPrivateProjectInfo.git ../iOSPrivateProjectInfo
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test scheme:"CRFSampleApp"
    bundle exec fastlane bump_all
    bundle exec fastlane keychains
    bundle exec fastlane certificates
    # bundle exec fastlane bump_build scheme:"CRFSampleApp" export_method:"app-store" project:"CRFSampleApp/CRFSampleApp.xcodeproj"
    bundle exec fastlane beta scheme:"CRFHeartRate" export_method:"app-store" project:"CRFHeartRate/CRFHeartRate.xcodeproj"
fi
exit $?

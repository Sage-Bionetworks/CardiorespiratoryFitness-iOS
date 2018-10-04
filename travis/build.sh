#!/bin/sh
set -ex
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then     # on pull requests
    echo "Build on PR"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test project:"CardiorespiratoryFitness/CardiorespiratoryFitness.xcodeproj"  scheme:"CRFTestApp"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" == "master" ]]; then  # non-tag commits to master branch
    echo "Build on merge to master"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test project:"CardiorespiratoryFitness/CardiorespiratoryFitness.xcodeproj"  scheme:"CRFTestApp"
    bundle exec fastlane ci_archive scheme:"CRFTestApp" export_method:"app-store" project:"CardiorespiratoryFitness/CardiorespiratoryFitness.xcodeproj"
    bundle exec fastlane ci_archive scheme:"CRFHeartRate" export_method:"app-store" project:"CRFHeartRate/CRFHeartRate.xcodeproj"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" =~ ^stable-.* ]]; then # non-tag commits to stable branches
    echo "Build on stable branch"
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane test project:"CardiorespiratoryFitness/CardiorespiratoryFitness.xcodeproj"  scheme:"CRFTestApp"
    bundle exec fastlane beta scheme:"CRFTestApp" export_method:"app-store" project:"CardiorespiratoryFitness/CardiorespiratoryFitness.xcodeproj"
    bundle exec fastlane beta scheme:"CRFHeartRate" export_method:"app-store" project:"CRFHeartRate/CRFHeartRate.xcodeproj"
fi
exit $?

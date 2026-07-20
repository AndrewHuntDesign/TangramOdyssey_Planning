# Convenience wrappers around xcodebuild.
#
# Prefer Xcode / the xcode-tools MCP for day-to-day work. Use these when the MCP test runner is
# unavailable (it cancels in some headless environments) or for CI / device-build checks.
#
# The simulator destination pins OS=latest so it satisfies the app's deployment target (iOS 26.5).

SCHEME  = TangramOdyssey
PROJECT = TangramOdyssey.xcodeproj
SIM     = platform=iOS Simulator,name=iPhone 17,OS=latest
DEVICE  = generic/platform=iOS
RESULTS = /tmp/TangramTests.xcresult

.PHONY: build test build-device ci clean

## Build the app for the simulator.
build:
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination '$(SIM)'

## Run all unit + UI tests on the simulator.
test:
	rm -rf $(RESULTS)
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(SIM)' -resultBundlePath $(RESULTS)

## Verify the app compiles for real device hardware (arm64), unsigned. A signed install
## additionally needs a connected device and a provisioning profile.
build-device:
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEVICE)' -configuration Release CODE_SIGNING_ALLOWED=NO

## CI entry point (also used by .github/workflows/ci.yml): full test suite, dependency-free.
ci:
	./Scripts/ci.sh

clean:
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME)

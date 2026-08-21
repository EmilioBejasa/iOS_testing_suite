.PHONY: setup open test-kit test-kit-ios test-app lint clean

setup:
	./Scripts/setup.sh

open: setup
	open QuoteBox.xcodeproj

test-kit:
	swift test

test-kit-ios:
	xcodebuild test -scheme iOSTestKit -destination "platform=iOS Simulator,name=iPhone 16"

test-app: setup
	xcodebuild test \
	  -project QuoteBox.xcodeproj \
	  -scheme QuoteBox \
	  -destination "platform=iOS Simulator,name=iPhone 16" \
	  -skip-testing:QuoteBoxTests/DummyJSONLiveContractTests

lint:
	swiftlint lint --strict

clean:
	rm -rf QuoteBox.xcodeproj

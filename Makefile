.PHONY: setup open test-kit test-kit-ios test-app lint clean

setup:
	./Scripts/setup.sh

open: setup
	open QuoteBox.xcodeproj

test-kit:
	swift test \
	  --skip testFetchAndPurchaseTipProduct \
	  --skip testIsEntitledReflectsRealPurchaseUnderTestSession \
	  --skip testCollectsRealTransactionUpdateAfterExternalPurchase

test-kit-ios:
	xcodebuild test -scheme iOSTestKit-Package -destination "platform=iOS Simulator,name=iPhone 16" \
	  -skip-testing:PurchaseSupportTests/PurchaseSupportTests/testFetchAndPurchaseTipProduct \
	  -skip-testing:PurchaseSupportTests/PurchaseSupportTests/testIsEntitledReflectsRealPurchaseUnderTestSession \
	  -skip-testing:AsyncSequenceCollectingTests/AsyncSequenceCollectingTests/testCollectsRealTransactionUpdateAfterExternalPurchase

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

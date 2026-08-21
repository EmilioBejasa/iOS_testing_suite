#if os(iOS)
import XCTest
import IdleTimerControlling

final class IdleTimerControllingTests: XCTestCase {
    func testMockRoundTripsDisabledState() async {
        let control = MockIdleTimerControl()

        await control.setIdleTimerDisabled(true)
        let disabled = await control.isIdleTimerDisabled()

        XCTAssertTrue(disabled)
    }

    func testMockDefaultsToNotDisabled() async {
        let control = MockIdleTimerControl()

        let disabled = await control.isIdleTimerDisabled()

        XCTAssertFalse(disabled)
    }

    /// Safe to exercise for real - set then read back round-trips cleanly
    /// against the real UIApplication.shared.isIdleTimerDisabled, with no
    /// persistent side effect beyond the test process's lifetime. Bridged
    /// through MainActor.run the same way SystemReviewRequester already
    /// does for UIApplication.shared.
    func testSystemControlRoundTripsAgainstRealApplication() async {
        let control = SystemIdleTimerControl()

        await control.setIdleTimerDisabled(true)
        let disabled = await control.isIdleTimerDisabled()
        XCTAssertTrue(disabled)

        await control.setIdleTimerDisabled(false)
        let reenabled = await control.isIdleTimerDisabled()
        XCTAssertFalse(reenabled)
    }
}
#endif

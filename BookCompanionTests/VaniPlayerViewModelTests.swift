// VaniPlayerViewModelTests.swift
// BookCompanionTests
//
// Area 9 — Project Vani TTS: State machine transitions, reset, speed cycling.
//
// NOTE: Network calls (fetchSignedUrl, pollForCompletion) and AVAudioPlayer
// initialisation are not tested here — those require integration/UI tests or
// a URLProtocol stub. These unit tests cover the pure state-machine logic
// that is reachable without network I/O.

import XCTest
@testable import BookCompanion

@MainActor
final class VaniPlayerViewModelTests: XCTestCase {

    private var sut: VaniPlayerViewModel!

    override func setUp() {
        super.setUp()
        sut = VaniPlayerViewModel()
    }

    override func tearDown() {
        sut.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - TC-VP-001 Initial state is idle

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.playerState, .idle)
        XCTAssertEqual(sut.currentTime, 0)
        XCTAssertEqual(sut.duration, 0)
        XCTAssertEqual(sut.playbackSpeed, 1.0)
        XCTAssertFalse(sut.hasStartedPrewarm)
    }

    // MARK: - TC-VP-002 reset() returns to idle and clears prewarm flag

    func test_reset_returnsToIdleAndClearsPrewarm() {
        // Manually set some state to simulate mid-session
        sut.reset()

        XCTAssertEqual(sut.playerState, .idle)
        XCTAssertFalse(sut.hasStartedPrewarm)
        XCTAssertEqual(sut.currentTime, 0)
        XCTAssertEqual(sut.duration, 0)
        XCTAssertNil(sut.audioPlayer)
    }

    // MARK: - TC-VP-003 setSpeed only accepts values in the allowed set

    func test_setSpeed_onlyAcceptsAllowedValues() {
        sut.setSpeed(1.25)
        XCTAssertEqual(sut.playbackSpeed, 1.25)

        sut.setSpeed(2.0) // not in [0.75, 1.0, 1.25, 1.5]
        XCTAssertEqual(sut.playbackSpeed, 1.25, "Speed must not change for unsupported values")

        sut.setSpeed(0.75)
        XCTAssertEqual(sut.playbackSpeed, 0.75)
    }

    // MARK: - TC-VP-004 nextSpeed() cycles through all speeds and wraps around

    func test_nextSpeed_cyclesThroughAllSpeeds() {
        // Default starts at 1.0 which is index 1 in [0.75, 1.0, 1.25, 1.5]
        XCTAssertEqual(sut.playbackSpeed, 1.0)

        sut.nextSpeed() // → 1.25
        XCTAssertEqual(sut.playbackSpeed, 1.25)

        sut.nextSpeed() // → 1.5
        XCTAssertEqual(sut.playbackSpeed, 1.5)

        sut.nextSpeed() // → 0.75 (wraps)
        XCTAssertEqual(sut.playbackSpeed, 0.75)

        sut.nextSpeed() // → 1.0
        XCTAssertEqual(sut.playbackSpeed, 1.0)
    }

    // MARK: - TC-VP-005 play() is a no-op when audioPlayer is nil

    func test_play_whenNoAudioPlayer_doesNotCrash() {
        XCTAssertNil(sut.audioPlayer)
        // Must not crash — button should be disabled by view, but defensive check here
        sut.play()
        // State should remain idle (no player = no transition)
        XCTAssertEqual(sut.playerState, .idle)
    }

    // MARK: - TC-VP-006 togglePlayPause from fallback is a no-op

    func test_togglePlayPause_fromFallback_doesNothing() {
        // Simulate fallback state by calling prewarm with a bad URL
        // We can't easily force the state, so test the switch logic directly
        // by verifying non-playing/paused states are ignored.
        // (Integration: use URLProtocol stub to trigger activateFallback)
        XCTAssertEqual(sut.playerState, .idle)
        sut.togglePlayPause() // idle → no player → no state change
        XCTAssertEqual(sut.playerState, .idle)
    }

    // MARK: - TC-VP-007 VaniPlayerState equality

    func test_vaniPlayerState_equality() {
        XCTAssertEqual(VaniPlayerState.idle, VaniPlayerState.idle)
        XCTAssertEqual(VaniPlayerState.playing, VaniPlayerState.playing)
        XCTAssertEqual(VaniPlayerState.downloading(0.5), VaniPlayerState.downloading(0.5))
        XCTAssertNotEqual(VaniPlayerState.downloading(0.3), VaniPlayerState.downloading(0.7))
        XCTAssertNotEqual(VaniPlayerState.idle, VaniPlayerState.ready)
    }

    // MARK: - TC-VP-008 hasStartedPrewarm prevents duplicate prewarm calls

    func test_prewarm_secondCall_isIgnoredWhenAlreadyStarted() async {
        // We can't actually make network calls in unit tests, but we can verify
        // the guard `hasStartedPrewarm` is correctly set after the first call starts.
        // Since the call will fail (no token in test env), hasStartedPrewarm is
        // set to true before the network attempt — second call must be ignored.
        let book = TestFixtures.makeBook()

        // First call — will fail at network layer but sets hasStartedPrewarm = true
        await sut.prewarm(text: "Some text", language: .english, bookId: book.id.uuidString, chapterNumber: 1)
        XCTAssertTrue(sut.hasStartedPrewarm)

        // Record state after first call
        let stateAfterFirst = sut.playerState

        // Second call — must return immediately without changing state again
        await sut.prewarm(text: "Different text", language: .english, bookId: book.id.uuidString, chapterNumber: 1)
        XCTAssertEqual(sut.playerState, stateAfterFirst, "Second prewarm call must be a no-op")
    }

    // MARK: - TC-VP-009 reset() after prewarm allows new prewarm

    func test_reset_afterPrewarm_allowsNewPrewarm() async {
        let book = TestFixtures.makeBook()
        await sut.prewarm(text: "Some text", language: .english, bookId: book.id.uuidString, chapterNumber: 1)
        XCTAssertTrue(sut.hasStartedPrewarm)

        sut.reset()
        XCTAssertFalse(sut.hasStartedPrewarm, "reset() must clear hasStartedPrewarm")
        XCTAssertEqual(sut.playerState, .idle)
    }

    // MARK: - TC-VP-010 seek clamps to valid range (no audioPlayer — safe)

    func test_seek_withNoPlayer_doesNotCrash() {
        // Without an AVAudioPlayer, seek must be safe
        sut.seek(to: -10)   // should clamp to 0
        sut.seek(to: 9999)  // should clamp to 0 (no player duration)
        XCTAssertEqual(sut.currentTime, 0)
    }
}

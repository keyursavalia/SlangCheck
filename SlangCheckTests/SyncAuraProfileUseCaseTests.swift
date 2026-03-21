// SlangCheckTests/SyncAuraProfileUseCaseTests.swift
// SlangCheck
//
// Unit tests for SyncAuraProfileUseCase.
// Covers: local save, local save failure, background sync dispatch,
// server-authoritative override, unauthenticated no-op, quiz result flow.

import XCTest
@testable import SlangCheck

// MARK: - MockAuraRepository

private actor MockAuraRepository: AuraRepository {
    private(set) var savedProfiles: [AuraProfile] = []
    private(set) var savedResults: [QuizResult]   = []
    private var throwOnSave = false

    func setThrowOnSave(_ value: Bool) { throwOnSave = value }

    func fetchProfile() async throws(AuraRepositoryError) -> AuraProfile? {
        savedProfiles.last
    }

    func saveProfile(_ profile: AuraProfile) async throws(AuraRepositoryError) {
        if throwOnSave { throw AuraRepositoryError.saveFailed(underlying: MockRepositoryError.forced) }
        savedProfiles.append(profile)
    }

    func saveQuizResult(_ result: QuizResult) async throws(AuraRepositoryError) {
        if throwOnSave { throw AuraRepositoryError.saveFailed(underlying: MockRepositoryError.forced) }
        savedResults.append(result)
    }

    func fetchQuizHistory() async throws(AuraRepositoryError) -> [QuizResult] {
        savedResults
    }
}

// MARK: - MockAuraSyncService

private final class MockAuraSyncService: AuraSyncService, @unchecked Sendable {
    /// When non-nil, `syncProfile` returns this instead of `localProfile`.
    var profileToReturn: AuraProfile?
    var throwUnauthenticated = false
    private(set) var profileSyncCount = 0
    private(set) var resultSyncCount  = 0

    func syncProfile(_ localProfile: AuraProfile) async throws(AuraSyncError) -> AuraProfile {
        profileSyncCount += 1
        if throwUnauthenticated { throw AuraSyncError.unauthenticated }
        return profileToReturn ?? localProfile
    }

    func syncQuizResult(_ result: QuizResult) async throws(AuraSyncError) {
        resultSyncCount += 1
    }
}

// MARK: - MockRepositoryError

private enum MockRepositoryError: Error { case forced }

// MARK: - SyncAuraProfileUseCaseTests

final class SyncAuraProfileUseCaseTests: XCTestCase {

    private var repository: MockAuraRepository!
    private var syncService: MockAuraSyncService!
    private var useCase: SyncAuraProfileUseCase!

    override func setUp() {
        super.setUp()
        repository  = MockAuraRepository()
        syncService = MockAuraSyncService()
        useCase     = SyncAuraProfileUseCase(auraRepository: repository, syncService: syncService)
    }

    override func tearDown() {
        useCase     = nil
        syncService = nil
        repository  = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeProfile(points: Int = 500, id: UUID = UUID()) -> AuraProfile {
        AuraProfile(id: id, totalPoints: points, streak: 0, lastActivityDate: nil, displayName: "Tester")
    }

    private func makeResult(points: Int = 200) -> QuizResult {
        let engine = AuraScoringEngine()
        let input  = ScoringInput(correctCount: 2, totalCount: 10, hintsUsed: 0, elapsedSeconds: 60)
        return engine.result(sessionID: UUID(), input: input)
    }

    // MARK: - Local Save

    func testExecuteSavesProfileLocallyBeforeSync() async throws {
        let profile = makeProfile(points: 200)
        try await useCase.execute(updatedProfile: profile)
        // Brief yield so the detached sync task can settle.
        try await Task.sleep(for: .milliseconds(150))

        let saved = await repository.savedProfiles
        XCTAssertTrue(saved.contains(where: { $0.id == profile.id }),
                      "Profile must be saved locally on execute.")
    }

    func testExecuteThrowsAuraRepositoryErrorWhenLocalSaveFails() async {
        await repository.setThrowOnSave(true)
        do {
            try await useCase.execute(updatedProfile: makeProfile())
            XCTFail("Expected AuraRepositoryError to be thrown.")
        } catch AuraRepositoryError.saveFailed {
            // Expected — local save failure must propagate.
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Background Sync Dispatch

    func testExecuteDispatchesSyncToBackground() async throws {
        try await useCase.execute(updatedProfile: makeProfile(points: 1_000))
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(syncService.profileSyncCount, 1,
                       "syncProfile should be called once after execute.")
    }

    // MARK: - Server-Authoritative Override

    func testServerProfileOverwritesLocalCacheWhenDifferent() async throws {
        let sharedID      = UUID()
        let localProfile  = makeProfile(points: 900, id: sharedID)
        let serverProfile = AuraProfile(
            id: sharedID,
            totalPoints: 1_500,   // server has a higher canonical value
            streak: 5,
            lastActivityDate: nil,
            displayName: "Tester"
        )
        syncService.profileToReturn = serverProfile

        try await useCase.execute(updatedProfile: localProfile)
        try await Task.sleep(for: .milliseconds(300))

        let saved = await repository.savedProfiles
        XCTAssertTrue(
            saved.contains(where: { $0.totalPoints == 1_500 }),
            "Server-authoritative value (1500 pts) must be written to local cache."
        )
    }

    func testNoSecondSaveWhenServerProfileMatchesLocal() async throws {
        let profile = makeProfile(points: 500)
        syncService.profileToReturn = nil  // sync returns identical profile

        try await useCase.execute(updatedProfile: profile)
        try await Task.sleep(for: .milliseconds(200))

        let saved = await repository.savedProfiles
        XCTAssertEqual(saved.count, 1, "Only the initial local save should occur.")
    }

    // MARK: - Unauthenticated

    func testUnauthenticatedSyncIsSwallowedAndDoesNotThrow() async throws {
        syncService.throwUnauthenticated = true
        let profile = makeProfile()

        // Must not throw — unauthenticated sync is a silent skip.
        try await useCase.execute(updatedProfile: profile)
        try await Task.sleep(for: .milliseconds(200))

        // Local save still happened.
        let saved = await repository.savedProfiles
        XCTAssertEqual(saved.count, 1)
    }

    // MARK: - Quiz Result

    func testSaveAndSyncResultSavesResultLocally() async throws {
        let result = makeResult()
        try await useCase.saveAndSyncResult(result)
        try await Task.sleep(for: .milliseconds(150))

        let history = await repository.savedResults
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.id, result.id)
    }

    func testSaveAndSyncResultCallsSyncService() async throws {
        let result = makeResult()
        try await useCase.saveAndSyncResult(result)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(syncService.resultSyncCount, 1)
    }

    func testSaveAndSyncResultThrowsWhenLocalSaveFails() async {
        await repository.setThrowOnSave(true)
        do {
            try await useCase.saveAndSyncResult(makeResult())
            XCTFail("Expected AuraRepositoryError to be thrown.")
        } catch AuraRepositoryError.saveFailed {
            // Expected.
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

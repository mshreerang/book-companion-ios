# BookCompanionTests

Generated test suite for BookCompanion iOS app.
**Generated:** March 2026 | **Target:** iOS 16+ / Swift 5.9+ / XCTest

---

## Directory Structure

```
BookCompanionTests/
├── Mocks/
│   ├── MockSummaryRepository.swift       — In-memory SummaryRepository
│   ├── MockProgressRepository.swift      — In-memory ProgressRepository
│   └── MockSummaryGeneratorSpy.swift     — Configurable SummaryGenerator spy
├── Fixtures/
│   └── TestFixtures.swift               — Factory methods for all test objects
└── Tests/
    ├── ModelTests.swift                  — Language, AIError, BookSummary, ReadingProgress
    ├── Repositories/
    │   ├── UserDefaultsSummaryRepositoryTests.swift
    │   └── UserDefaultsProgressRepositoryTests.swift
    ├── ViewModels/
    │   ├── SummaryViewModelTests.swift
    │   ├── CharactersViewModelTests.swift
    │   ├── CharacterCardsViewModelTests.swift
    │   ├── ProgressInputViewModelTests.swift
    │   ├── BookSearchViewModelTests.swift
    │   └── PureFunctionTests.swift       — CharacterAvatar, BookCard math, parseSegments, UsageStats
    ├── Services/
    │   └── ServicePureFunctionTests.swift — AgeVerification, ServerAI validation, formatBytes
    ├── Chat/
    │   ├── ChatSessionStoreTests.swift
    │   ├── CharacterChatMessageTests.swift
    │   └── CharacterChatViewModelTests.swift  ⚠️ Inferred — update when VM available
    ├── TTS/
    │   ├── VaniPlayerViewModelTests.swift
    │   └── VaniAudioDownloaderTests.swift
    └── Accessibility/
        └── AccessibilityTests.swift
```

---

## Xcode Setup

### Step 1 — Add the Test Target

1. In Xcode → **File → New → Target** → **Unit Testing Bundle**
2. Name it `BookCompanionTests`
3. Set **Target to be Tested** to `BookCompanion`

### Step 2 — Copy Files

Copy this entire `BookCompanionTests/` folder into your Xcode project at:
```
/Users/shree/ViVa Projects/BookCompanion/BookCompanionTests/
```

Then in Xcode, right-click the `BookCompanionTests` group → **Add Files** → select all files, ensuring **Target: BookCompanionTests** is checked.

### Step 3 — Add @testable Import Access

In `BookCompanion` app target → **Build Settings** → search `ENABLE_TESTABILITY` → set to **Yes** for Debug.

### Step 4 — Run Tests

```
Cmd+U               — Run all tests
Cmd+Ctrl+U          — Run tests without building
```

Or from terminal:
```bash
xcodebuild test \
  -project "/Users/shree/ViVa Projects/BookCompanion/BookCompanion.xcodeproj" \
  -scheme BookCompanion \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:BookCompanionTests
```

---

## Known Limitations & Action Items

### ⚠️ CharacterChatViewModel Missing
`CharacterChatViewModelTests.swift` is inferred from `CharacterChatView.swift`, `CharacterChatMessage.swift`, and `ChatSessionStore.swift`.
**When the file is available:** Update `CharacterChatViewModelTests.swift` to reference the real `CharacterChatViewModel` type directly.

### ⚠️ Singleton Dependencies
`BookManager`, `TextToSpeechManager`, `StoreManager`, `AuthManager` use `.shared` singletons.
Tests that instantiate `BookManager()` directly may carry over state from previous test runs.
**Recommended fix:** Extract `BookManagerProtocol` and inject a `MockBookManager` in tests.

### ⚠️ Network Tests
Tests that touch real network calls (no token in test env) will exercise error paths only.
To test success paths, add a `URLProtocolStub`:
```swift
URLProtocol.registerClass(MockURLProtocol.self)
```
A `MockURLProtocol` stub is not included in this batch but is straightforward to add.

### ⚠️ UserDefaultsSummaryRepository Injection
`UserDefaultsSummaryRepository` currently hardcodes `UserDefaults.standard`.
Passing a custom suite name in the initialiser would allow proper isolation.
Until then, tests use unique book IDs to avoid key collisions.

---

## Test Coverage Map

| Area | Files | Tests | Status |
|------|-------|-------|--------|
| Core Models | ModelTests.swift | 16 | ✅ |
| Repositories | UserDefaultsSummaryRepository*, UserDefaultsProgress* | 10 | ✅ |
| Pure Functions | PureFunctionTests, ServicePureFunctionTests | 22 | ✅ |
| Character Chat | ChatSessionStore, CharacterChatMessage, ChatViewModel | 24 | ✅ (VM inferred) |
| ViewModels | Summary, Characters, CharacterCards, ProgressInput, BookSearch | 40 | ✅ |
| TTS / Vani | VaniPlayerViewModel, VaniAudioDownloader | 16 | ✅ |
| Accessibility | AccessibilityTests | 4 | ✅ |
| **Total** | **13 files** | **~132 tests** | |

import Foundation

class AgeVerificationService {
    static let shared = AgeVerificationService()
    
    private let ageConfirmedKey = "ageConfirmed"
    
    private init() {}
    
    func isAgeConfirmed() -> Bool {
        return UserDefaults.standard.bool(forKey: ageConfirmedKey)
    }
    
    func confirmAge() {
        UserDefaults.standard.set(true, forKey: ageConfirmedKey)
    }
    
    func reset() {
        UserDefaults.standard.removeObject(forKey: ageConfirmedKey)
    }
}

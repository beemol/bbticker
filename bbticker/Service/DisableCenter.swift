import Foundation
import Combine

@MainActor
class DisableCenter: ObservableObject {
    @Published var isActive: Bool = false
    @Published var message: String = ""
    
    init() {}
    
    func apply(message: String) {
        print("DisableCenter.apply called with message: \(message)")
        isActive = true
        self.message = message
        print("DisableCenter.isActive is now: \(isActive)")
    }
} 

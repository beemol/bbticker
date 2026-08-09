import Foundation
import Combine

@MainActor
class DisableCenter: ObservableObject {
    @Published var isActive: Bool = false
    @Published var message: String = ""
    
    init() {}
    
    func apply(message: String) {
        AppLog.service.info("DisableCenter.apply called with message: \(message)")
        isActive = true
        self.message = message
    }
} 

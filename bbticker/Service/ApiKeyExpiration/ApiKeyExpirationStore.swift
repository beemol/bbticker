//
//  ApiKeyExpirationStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 01/06/2026.
//

import Foundation
import LLCore

protocol ApiKeyInfo: Sendable {
    var expiredAt: Date? { get }
    var deadlineDay: Int? { get }
    var createdAt: Date { get }
}

extension ApiKeyInfoData: ApiKeyInfo { }

enum LoadingState {
    case idle, loading, success, failure
}

struct ApiKeyExpirationState {
    var info: ApiKeyInfo?
    var loadingState: LoadingState = .idle
    var expirationWarnings: String = ""
}

enum ApiKeyExpirationAction {
    case checkExpiration(ExchangeType)
    case dataLoaded(ApiKeyInfo)
    case loadingFailed(Error)
}

@Observable
class ApiKeyExpirationStateStore {
    
    init(repository: WalletRepositoryProtocol) {
        self.repository = repository
    }
    
    private let repository: WalletRepositoryProtocol
    
    var state = ApiKeyExpirationState()
    
    @MainActor
    func dispatch(_ action: ApiKeyExpirationAction) {
        state = reduce(state: state, action: action)
        handleSideEffects(action: action)
    }
    
    func reduce(state: ApiKeyExpirationState, action: ApiKeyExpirationAction) -> ApiKeyExpirationState {
        var newState = state
        
        switch action {
        case .checkExpiration(let exchangeType):
            newState.loadingState = .loading
            newState.expirationWarnings = ""
            break
        case .dataLoaded(let info):
            newState.loadingState = .success
            newState.info = info
        case .loadingFailed(let error):
            newState.loadingState = .failure
            newState.expirationWarnings = error.localizedDescription
        }
        
        return newState
    }
    
    @MainActor
    func handleSideEffects(action: ApiKeyExpirationAction) {
        switch action {
        case .checkExpiration(let exchangeType):
            Task {
                do {
                    let result = try await repository.getApiKeyInfo(for: exchangeType)
                    dispatch(.dataLoaded(result))
                } catch {
                    dispatch(.loadingFailed(error))
                }
            }
        case .dataLoaded, .loadingFailed:
            break
        }
    }
}

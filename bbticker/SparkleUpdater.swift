//
//  SparkleUpdater.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 05/08/2025.
//

#if os(macOS) && STANDALONE
import Sparkle

class SparkleUpdater: ObservableObject {
    let updaterController: SPUStandardUpdaterController
    
    init() {
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    func checkForUpdates() {
        self.updaterController.checkForUpdates(nil)
    }
}
#endif

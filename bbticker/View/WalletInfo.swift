//
//  WalletInfo.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 07/06/2026.
//

import SwiftUI

struct WalletInfo: View {
    var walletState: StaleTracked<WalletState>
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing) {
                HStack() {
                    Text("Equity:")
                        .font(.subheadline)
                    .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f", walletState.wrappedValue.equity))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                HStack {
                    Text("Balance:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f", walletState.wrappedValue.balance))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                         
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("MM: \(String(format: "%.1f", walletState.wrappedValue.maintenanceMarginPercentage))")
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(walletState.wrappedValue.maintenanceMarginColor)
                
                if let lastUpdated = walletState.lastUpdated {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let seconds = Int(context.date.timeIntervalSince(lastUpdated))
                        
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("\(seconds)s")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
struct WalletInfo_Previews: PreviewProvider {
    static var previews: some View {
        let walletState: StaleTracked<WalletState> = .init(wrappedValue: WalletState(equity: 1.0, balance: 2.0, maintenanceMarginPercentage: 12))
        WalletInfo(walletState: walletState)
        .frame(width: 220, height: 100)
    }
}
#endif

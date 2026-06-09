

#if os(macOS)

import SwiftUI
import CoreImage.CIFilterBuiltins
import FirebaseRemoteConfig


// MARK: - DonationView
struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: DonationViewModel
    
    @State private var showingQRCode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support BBTicker Development")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            
            Divider()
            
            // Main Wallet Address Section
            if !viewModel.wallets.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Wallet Address")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        // QR Code Button
                        Button {
                            showingQRCode = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "qrcode")
                                Text("QR Code")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        // Copy Button
                        Button {
                            viewModel.copyToClipboard(address: viewModel.wallets.first?.address ?? "", walletId: "wallet")
                        } label: {
                            if viewModel.copiedAddress == "wallet" {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Copied!")
                                }
                                .foregroundColor(.green)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Wallet Address Display
                    Text(viewModel.wallets.first?.address ?? "")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            
            // Networks Information (Compact)
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading wallet information...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(height: 80)
            } else if !viewModel.wallets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported Networks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 6) {
                        ForEach(viewModel.wallets) { wallet in
                            NetworkInfoRow(wallet: wallet)
                                           }
               }
           }
       }

       // Instructions Section
       if let instructions = viewModel.instructions {
           VStack(alignment: .leading, spacing: 12) {
               Text(instructions.instructionsTitle)
                   .font(.subheadline)
                   .fontWeight(.medium)
                   .foregroundColor(.primary)
               
               VStack(alignment: .leading, spacing: 6) {
                   ForEach(instructions.donationSteps, id: \.stepNumber) { step in
                       HStack(alignment: .top, spacing: 8) {
                           Text("\(step.stepNumber).")
                               .font(.caption)
                               .fontWeight(.medium)
                               .foregroundColor(.secondary)
                               .frame(width: 16, alignment: .leading)
                           
                           Text(step.description)
                               .font(.caption)
                               .foregroundColor(.secondary)
                               .fixedSize(horizontal: false, vertical: true)
                           
                           Spacer()
                       }
                   }
               }
               .padding(10)
               .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
               .cornerRadius(8)
               
               Text(instructions.confirmationMessage)
                   .font(.caption)
                   .foregroundColor(.secondary)
                   .multilineTextAlignment(.leading)
           }
       }

       Spacer()

       // Footer
       VStack(spacing: 8) {
                Text("🙏 Thank you for your support!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .onAppear {
            viewModel.loadWalletConfiguration()
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(address: viewModel.wallets.first?.address ?? "")
        }
    }
}

// MARK: - Network Info Row

struct NetworkInfoRow: View {
    let wallet: DisplayWallet
    
    var body: some View {
        HStack(spacing: 8) {
            // Network Name
            Text(wallet.networkName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Supported Currencies (Compact)
            Text(formatCurrencies(wallet.currencies))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    private func formatCurrencies(_ currencies: [String]) -> String {
        if currencies.count <= 3 {
            return currencies.joined(separator: ", ")
        } else {
            let first = currencies.prefix(3).joined(separator: ", ")
            return "\(first) +\(currencies.count - 3) more"
        }
    }
}

// MARK: - QR Code View

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let address: String
    @State private var qrImage: NSImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Wallet Address QR Code")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            
            Divider()
            
            // QR Code Display
            if let qrImage = qrImage {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        ProgressView()
                    )
            }
            
            // Address Text
            VStack(spacing: 8) {
                Text("Wallet Address:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(address)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity)
            }
            
            // Save Button
//            Button("Save QR Code") {
//                saveQRCode()
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(qrImage == nil)
            
            Spacer()
        }
        .padding(24)
        .frame(width: 350, height: 450)
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(address.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            // Scale up the QR code for better quality
            let scaleX = 200 / outputImage.extent.size.width
            let scaleY = 200 / outputImage.extent.size.height
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = NSImage(cgImage: cgImage, size: NSSize(width: 200, height: 200))
            }
        }
    }
    
    private func saveQRCode() {
        guard let qrImage = qrImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "wallet-qr-code.png"
        savePanel.title = "Save QR Code"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = qrImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: url)
                    } catch {
                        print("Failed to save QR code: \(error)")
                    }
                }
            }
        }
    }
}

#if DEBUG
struct DonationView_Previews: PreviewProvider {
    static var previews: some View {
        DonationView(viewModel: DonationViewModel(remoteConfigManager: Mocks.MockRemoteConfigManager()))
            .frame(width: 400, height: 350)
    }
}
#endif

#endif

import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var html = welcomeHTML
    @State private var showingImporter = false
    @State private var errorMessage: String?
    @State private var fileName: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Text("PEPPOL Viewer")
                        .font(.title2)
                        .bold()

                    if let fileName {
                        Text("— \(fileName)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Open XML…") { showingImporter = true }
            }
            .padding()
            Divider()
            HTMLView(html: html)
        }
        .frame(minWidth: 820, minHeight: 620)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.xml]) { result in
            do {
                let url = try result.get()
                fileName = url.lastPathComponent
                print(">>>>>>>>>>>>> Selected:", url.path)
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                print(">>>>>>>>>>>>>>>>>> IMPORT:", url.path)
                let data = try Data(contentsOf: url)
                let invoice = try PEPPOLParser.parse(data: data, requirePeppolMarker: false)
                html = InvoiceHTMLRenderer.render(invoice)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert("Could not open invoice", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

private struct HTMLView: NSViewRepresentable {
    let html: String
    func makeNSView(context: Context) -> WKWebView { WKWebView() }
    func updateNSView(_ webView: WKWebView, context: Context) { webView.loadHTMLString(html, baseURL: nil) }
}

private let welcomeHTML = """
<html><body style="font:16px -apple-system;padding:40px;color:#667085"><h1 style="color:#1f2937">PEPPOL Viewer</h1><p>Open a PEPPOL / UBL XML invoice to display it here.</p><p>Once the Quick Look extension is enabled, select an invoice in Finder and press Space.</p></body></html>
"""

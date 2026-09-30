import Foundation
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void
    ) {
        do {
            let data = try Data(contentsOf: request.fileURL)

            do {
                // PEPPOL invoice → our formatted invoice preview
                let invoice = try PEPPOLParser.parse(
                    data: data,
                    requirePeppolMarker: true
                )

                let html = InvoiceHTMLRenderer.render(invoice)

                let reply = makeHTMLReply(
                    html: html,
                    title: invoice.id.isEmpty
                        ? request.fileURL.lastPathComponent
                        : "\(invoice.documentType) \(invoice.id)"
                )

                handler(reply, nil)

            } catch {
                // Not PEPPOL → display the XML as XML
                let html = renderXML(
                    data: data,
                    filename: request.fileURL.lastPathComponent
                )

                let reply = makeHTMLReply(
                    html: html,
                    title: request.fileURL.lastPathComponent
                )

                handler(reply, nil)
            }

        } catch {
            handler(nil, error)
        }
    }

    // MARK: - Quick Look reply

    private func makeHTMLReply(
        html: String,
        title: String
    ) -> QLPreviewReply {

        let reply = QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 1000, height: 760)
        ) { _ in

            guard let data = html.data(using: .utf8) else {
                throw PeppolError.invalidXML
            }

            return data
        }

        reply.title = title
        reply.stringEncoding = .utf8

        return reply
    }

    // MARK: - Generic XML preview

    private func renderXML(
        data: Data,
        filename: String
    ) -> String {

        let xml = String(data: data, encoding: .utf8)
            ?? String(decoding: data, as: UTF8.self)

        let escapedXML = escapeHTML(xml)

        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">

        <style>

        :root {
            color-scheme: light dark;
        }

        body {
            margin: 0;
            padding: 28px;
            font-family:
                -apple-system,
                BlinkMacSystemFont,
                sans-serif;
        }

        h1 {
            font-size: 18px;
            margin: 0 0 18px 0;
        }

        pre {
            margin: 0;
            padding: 20px;

            font-family:
                ui-monospace,
                SFMono-Regular,
                Menlo,
                Monaco,
                monospace;

            font-size: 13px;
            line-height: 1.5;

            white-space: pre-wrap;
            overflow-wrap: anywhere;

            border-radius: 10px;

            background:
                rgba(128,128,128,0.10);
        }

        </style>
        </head>

        <body>

        <h1>\(escapeHTML(filename))</h1>

        <pre>\(escapedXML)</pre>

        </body>
        </html>
        """
    }

    // MARK: - HTML escaping

    private func escapeHTML(_ string: String) -> String {

        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

import Foundation

struct InvoiceHTMLRenderer {
    static func render(_ invoice: PeppolInvoice) -> String {
        let lines = invoice.lines.map { line in
            """
            <tr>
              <td>\(esc(line.id))</td>
              <td><strong>\(esc(line.name))</strong>\(line.description.isEmpty ? "" : "<div class=\"muted\">\(esc(line.description))</div>")</td>
              <td class="num">\(esc(line.quantity)) \(esc(line.unitCode))</td>
              <td class="num">\(money(line.unitPrice, invoice.currency))</td>
              <td class="num">\(money(line.lineAmount, invoice.currency))</td>
            </tr>
            """
        }.joined()

        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        :root{color-scheme:light dark}*{box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text",sans-serif;margin:0;padding:28px;background:#f5f7fb;color:#1f2937}.sheet{max-width:980px;margin:auto;background:white;border:1px solid #dbe2ea;border-radius:18px;overflow:hidden;box-shadow:0 12px 35px rgba(0,0,0,.10)}header{padding:24px 28px;border-bottom:1px solid #e5e7eb;display:flex;justify-content:space-between;gap:20px}.title{font-size:27px;font-weight:760}.muted{color:#6b7280;font-size:13px;margin-top:4px}.badge{background:#ecfdf5;color:#065f46;padding:7px 11px;border-radius:999px;height:max-content;font-weight:700}.section{padding:22px 28px;border-bottom:1px solid #e5e7eb}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.label{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#6b7280;margin-bottom:6px}.party{font-size:16px;font-weight:700}.address{font-weight:400;line-height:1.5;margin-top:5px}.meta{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.box{border:1px solid #e5e7eb;border-radius:12px;padding:12px}.value{font-weight:650}table{width:100%;border-collapse:collapse}th,td{padding:11px 9px;border-bottom:1px solid #e5e7eb;text-align:left;font-size:14px}th{color:#6b7280;background:#fafafa}.num{text-align:right;white-space:nowrap}.totals{margin-left:auto;max-width:390px}.row{display:flex;justify-content:space-between;padding:7px 0}.payable{font-size:19px;font-weight:760;border-top:2px solid #e5e7eb;margin-top:6px;padding-top:12px}@media(max-width:700px){body{padding:10px}.grid,.meta{grid-template-columns:1fr}.section,header{padding:18px}}
        @media(prefers-color-scheme:dark){body{background:#1b1d22;color:#f3f4f6}.sheet{background:#25272d;border-color:#3a3d46}.section,header,th,td{border-color:#3a3d46}.box{border-color:#3a3d46}th{background:#2c2f36}.muted,.label,th{color:#a7abb5}.badge{background:#123c31;color:#9de6c8}}
        </style></head><body>
        <div class="sheet">
        <header><div><div class="title">\(esc(invoice.documentType)) \(esc(invoice.id))</div><div class="muted">PEPPOL / UBL electronic invoice</div></div><div class="badge">\(esc(invoice.currency))</div></header>
        <div class="section meta"><div class="box"><div class="label">Issue date</div><div class="value">\(esc(invoice.issueDate))</div></div><div class="box"><div class="label">Due date</div><div class="value">\(esc(invoice.dueDate.isEmpty ? "—" : invoice.dueDate))</div></div><div class="box"><div class="label">Invoice number</div><div class="value">\(esc(invoice.id))</div></div></div>
        <div class="section grid"><div><div class="label">Supplier</div><div class="party">\(esc(invoice.supplier.name))</div><div class="address">\(esc(invoice.supplier.formattedAddress))</div><div class="muted">VAT / Company: \(esc(invoice.supplier.companyID))</div></div><div><div class="label">Customer</div><div class="party">\(esc(invoice.customer.name))</div><div class="address">\(esc(invoice.customer.formattedAddress))</div><div class="muted">VAT / Company: \(esc(invoice.customer.companyID))</div></div></div>
        <div class="section" style="overflow:auto"><table><thead><tr><th>Line</th><th>Description</th><th class="num">Qty</th><th class="num">Unit price</th><th class="num">Total</th></tr></thead><tbody>\(lines.isEmpty ? "<tr><td colspan=\"5\" class=\"muted\">No invoice lines found.</td></tr>" : lines)</tbody></table></div>
        <div class="section"><div class="totals"><div class="row"><span>Net</span><span>\(money(invoice.taxExclusiveAmount, invoice.currency))</span></div><div class="row"><span>Tax</span><span>\(money(invoice.taxAmount, invoice.currency))</span></div><div class="row"><span>Total incl. tax</span><span>\(money(invoice.taxInclusiveAmount, invoice.currency))</span></div><div class="row payable"><span>Payable</span><span>\(money(invoice.payableAmount, invoice.currency))</span></div></div></div>
        </div></body></html>
        """
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
         .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func money(_ raw: String, _ currency: String) -> String {
        guard !raw.isEmpty else { return "—" }
        guard let n = Decimal(string: raw.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) else {
            return esc(raw + " " + currency)
        }
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = currency.isEmpty ? "EUR" : currency
        nf.locale = Locale.current
        return esc(nf.string(from: n as NSDecimalNumber) ?? "\(raw) \(currency)")
    }
}

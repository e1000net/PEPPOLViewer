import Foundation

final class PEPPOLParser: NSObject, XMLParserDelegate {
    private var invoice = PeppolInvoice()
    private var stack: [String] = []
    private var textBuffer = ""
    private var currentLine: InvoiceLine?
    private var rootSeen = false
    private var parseFailed = false

    static func parse(data: Data, requirePeppolMarker: Bool = true) throws -> PeppolInvoice {
        let delegate = PEPPOLParser()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        guard parser.parse(), !delegate.parseFailed else { throw parser.parserError ?? PeppolError.invalidXML }
        guard delegate.rootSeen else { throw PeppolError.unsupportedDocument }

        let result = delegate.invoice
        if requirePeppolMarker {
            let marker = (result.customizationID + " " + result.profileID).lowercased()
            let looksPeppol = marker.contains("peppol") || marker.contains("cen.eu:en16931") || marker.contains("urn:fdc:peppol")
            guard looksPeppol else { throw PeppolError.notPeppol }
        }
        return result
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        let name = elementName
        if stack.isEmpty {
            guard name == "Invoice" || name == "CreditNote" else {
                parseFailed = true
                parser.abortParsing()
                return
            }
            invoice.documentType = name
            rootSeen = true
        }

        stack.append(name)
        textBuffer = ""

        if name == "InvoiceLine" || name == "CreditNoteLine" {
            currentLine = InvoiceLine()
        }

        if name == "InvoicedQuantity" || name == "CreditedQuantity" {
            currentLine?.unitCode = attributeDict["unitCode"] ?? ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let value = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = stack.joined(separator: "/")

        func has(_ suffix: String) -> Bool { path.hasSuffix(suffix) }
        func contains(_ segment: String) -> Bool { path.contains(segment) }

        if currentLine != nil {
            if has("InvoiceLine/ID") || has("CreditNoteLine/ID") { currentLine?.id = value }
            else if has("Item/Name") { currentLine?.name = value }
            else if has("Item/Description") { currentLine?.description = value }
            else if has("InvoicedQuantity") || has("CreditedQuantity") { currentLine?.quantity = value }
            else if has("Price/PriceAmount") { currentLine?.unitPrice = value }
            else if has("InvoiceLine/LineExtensionAmount") || has("CreditNoteLine/LineExtensionAmount") { currentLine?.lineAmount = value }
        }

        if has("Invoice/ID") || has("CreditNote/ID") { invoice.id = value }
        else if has("IssueDate") { invoice.issueDate = value }
        else if has("DueDate") { invoice.dueDate = value }
        else if has("DocumentCurrencyCode") { invoice.currency = value }
        else if has("CustomizationID") { invoice.customizationID = value }
        else if has("ProfileID") { invoice.profileID = value }

        if contains("AccountingSupplierParty/Party/") {
            assignPartyField(&invoice.supplier, path: path, value: value)
        } else if contains("AccountingCustomerParty/Party/") {
            assignPartyField(&invoice.customer, path: path, value: value)
        }

        if has("PaymentMeans/PaymentMeansCode") { invoice.paymentMeansCode = value }
        else if has("PaymentMeans/PayeeFinancialAccount/ID") { invoice.accountID = value }
        else if has("TaxTotal/TaxAmount"), invoice.taxAmount.isEmpty { invoice.taxAmount = value }
        else if has("LegalMonetaryTotal/LineExtensionAmount") { invoice.lineExtensionAmount = value }
        else if has("LegalMonetaryTotal/TaxExclusiveAmount") { invoice.taxExclusiveAmount = value }
        else if has("LegalMonetaryTotal/TaxInclusiveAmount") { invoice.taxInclusiveAmount = value }
        else if has("LegalMonetaryTotal/PayableAmount") { invoice.payableAmount = value }

        if (elementName == "InvoiceLine" || elementName == "CreditNoteLine"), let line = currentLine {
            invoice.lines.append(line)
            currentLine = nil
        }

        if !stack.isEmpty { stack.removeLast() }
        textBuffer = ""
    }

    private func assignPartyField(_ party: inout Party, path: String, value: String) {
        guard !value.isEmpty else { return }
        if path.hasSuffix("PartyName/Name") { party.name = value }
        else if path.hasSuffix("PartyLegalEntity/RegistrationName"), party.name.isEmpty { party.name = value }
        else if path.hasSuffix("EndpointID") { party.endpointID = value }
        else if path.hasSuffix("PartyTaxScheme/CompanyID") { party.companyID = value }
        else if path.hasSuffix("PostalAddress/StreetName") { party.street = value }
        else if path.hasSuffix("PostalAddress/AdditionalStreetName") { party.additionalStreet = value }
        else if path.hasSuffix("PostalAddress/PostalZone") { party.postalCode = value }
        else if path.hasSuffix("PostalAddress/CityName") { party.city = value }
        else if path.hasSuffix("PostalAddress/Country/IdentificationCode") { party.countryCode = value }
    }
}

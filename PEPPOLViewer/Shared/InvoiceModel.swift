import Foundation

struct Party {
    var name = ""
    var companyID = ""
    var endpointID = ""
    var street = ""
    var additionalStreet = ""
    var postalCode = ""
    var city = ""
    var countryCode = ""

    var formattedAddress: String {
        [street, additionalStreet, [postalCode, city].filter { !$0.isEmpty }.joined(separator: " "), countryCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

struct InvoiceLine {
    var id = ""
    var name = ""
    var description = ""
    var quantity = ""
    var unitCode = ""
    var unitPrice = ""
    var lineAmount = ""
}

struct PeppolInvoice {
    var documentType = "Invoice"
    var id = ""
    var issueDate = ""
    var dueDate = ""
    var currency = "EUR"
    var customizationID = ""
    var profileID = ""
    var supplier = Party()
    var customer = Party()
    var paymentMeansCode = ""
    var accountID = ""
    var taxAmount = ""
    var lineExtensionAmount = ""
    var taxExclusiveAmount = ""
    var taxInclusiveAmount = ""
    var payableAmount = ""
    var lines: [InvoiceLine] = []
}

enum PeppolError: LocalizedError {
    case invalidXML
    case unsupportedDocument
    case notPeppol

    var errorDescription: String? {
        switch self {
        case .invalidXML: return "The file is not valid XML."
        case .unsupportedDocument: return "Only UBL Invoice and CreditNote documents are supported."
        case .notPeppol: return "This XML file does not look like a PEPPOL / UBL invoice."
        }
    }
}

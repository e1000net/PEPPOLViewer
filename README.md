# PEPPOL Viewer for macOS

A lightweight macOS application and Quick Look extension for previewing
PEPPOL / UBL XML invoices directly from Finder.

Select a PEPPOL XML invoice in Finder and press **Space** to get a readable
invoice preview instead of raw XML.

## Features

- Quick Look preview for PEPPOL / UBL invoices
- Displays supplier and customer information
- Invoice number and dates
- Invoice lines and totals
- Generic XML files remain readable as XML
- Standalone macOS application for opening invoices
- Fully local processing — invoice data is not uploaded anywhere

## Usage

After installing PEPPOL Viewer:

1. Select a PEPPOL XML invoice in Finder.
2. Press **Space**.
3. Quick Look displays a formatted invoice preview.

Non-PEPPOL XML files are displayed as readable XML.

## Building

Open:

`PEPPOLViewer.xcodeproj`

in Xcode and build the `PEPPOLViewer` target.

The project also contains the `PEPPOLQuickLookPreview` extension used by Finder.

## Sample

A sample invoice is available in:

`PEPPOLViewer/Samples/sample-peppol-invoice.xml`

## Privacy

PEPPOL Viewer processes XML files locally on your Mac.

No invoice data is transmitted to an external service.

## License

MIT
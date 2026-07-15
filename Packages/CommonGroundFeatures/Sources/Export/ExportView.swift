import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var families: [Family]
    @Query private var threads: [MessageThread]

    @State private var dateRange = "Last 12 months"
    @State private var includeMessages = true
    @State private var includeExpenses = true
    @State private var includeCalendar = true
    @State private var includeMedical = true
    @State private var includeDocuments = true
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        Form {
            Section(L10n.exportSectionRange) {
                Picker(L10n.exportRangeLabel, selection: $dateRange) {
                    Text(L10n.exportRange3months).tag("Last 3 months")
                    Text(L10n.exportRange12months).tag("Last 12 months")
                    Text(L10n.exportRangeAllTime).tag("All time")
                }
            }

            Section(L10n.exportSectionInclude) {
                Toggle(L10n.exportIncludeMessages, isOn: $includeMessages)
                Toggle(L10n.exportIncludeExpenses, isOn: $includeExpenses)
                Toggle(L10n.exportIncludeCalendar, isOn: $includeCalendar)
                Toggle(L10n.exportIncludeMedical, isOn: $includeMedical)
                Toggle(L10n.exportIncludeDocuments, isOn: $includeDocuments)
            }

            Section {
                Button {
                    exportPDF()
                } label: {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                        } else {
                            Label(L10n.exportGeneratePDF, systemImage: "doc.richtext")
                        }
                        Spacer()
                    }
                }
                .disabled(isExporting || families.isEmpty)

                Button {
                    exportJSON()
                } label: {
                    HStack {
                        Spacer()
                        Label(L10n.exportRawJSON, systemImage: "curlybraces")
                        Spacer()
                    }
                }
                .disabled(isExporting || families.isEmpty)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text(L10n.exportIntegrityFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.moreCourtExport)
        #if canImport(UIKit)
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        #endif
    }

    private var options: CourtExportOptions {
        CourtExportOptions(
            rangeMonths: rangeMonths,
            includeMessages: includeMessages,
            includeExpenses: includeExpenses,
            includeCalendar: includeCalendar,
            includeMedical: includeMedical,
            includeDocuments: includeDocuments
        )
    }

    private var rangeMonths: Int? {
        switch dateRange {
        case "Last 3 months": 3
        case "Last 12 months": 12
        default: nil
        }
    }

    private func exportPDF() {
        guard let family = families.first else { return }
        isExporting = true
        errorMessage = nil
        do {
            exportURL = try CourtExportService.generatePDF(
                context: modelContext,
                family: family,
                threads: threads,
                options: options
            )
            showShare = true
        } catch {
            errorMessage = L10n.exportPdfError
        }
        isExporting = false
    }

    private func exportJSON() {
        guard let family = families.first else { return }
        isExporting = true
        errorMessage = nil
        do {
            exportURL = try CourtExportService.generateJSON(
                context: modelContext,
                family: family,
                options: options
            )
            showShare = true
        } catch {
            errorMessage = L10n.exportJsonError
        }
        isExporting = false
    }
}

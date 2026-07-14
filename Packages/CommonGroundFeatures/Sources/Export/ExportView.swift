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
            Section("Export Range") {
                Picker("Range", selection: $dateRange) {
                    Text("Last 3 months").tag("Last 3 months")
                    Text("Last 12 months").tag("Last 12 months")
                    Text("All time").tag("All time")
                }
            }

            Section("Include") {
                Toggle("Messages", isOn: $includeMessages)
                Toggle("Expenses", isOn: $includeExpenses)
                Toggle("Calendar", isOn: $includeCalendar)
                Toggle("Medical Records", isOn: $includeMedical)
                Toggle("Documents", isOn: $includeDocuments)
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
                            Label("Generate PDF Report", systemImage: "doc.richtext")
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
                        Label("Export Raw Data (JSON)", systemImage: "curlybraces")
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
                Text("PDF exports include a SHA-256 integrity hash for court admissibility. All records are timestamped and immutable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Court Export")
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
            errorMessage = "PDF export failed."
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
            errorMessage = "JSON export failed."
        }
        isExporting = false
    }
}

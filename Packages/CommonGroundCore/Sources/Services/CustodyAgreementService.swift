import Foundation
import SwiftData
import CryptoKit

#if canImport(UIKit)
import UIKit
#endif

public enum CustodyAgreementError: LocalizedError {
    case alreadySigned
    case notAuthorized
    case emptySignature
    case missingFamily

    public var errorDescription: String? {
        switch self {
        case .alreadySigned: "You have already signed this agreement."
        case .notAuthorized: "You are not a signing party on this agreement."
        case .emptySignature: "Please draw your signature before signing."
        case .missingFamily: "No family found."
        }
    }
}

@MainActor
public enum CustodyAgreementService {
    public static let defaultTemplate = """
    CUSTODY AND PARENTING AGREEMENT

    The undersigned parents/guardians agree to cooperate in raising their child(ren) and to follow the custody schedule, exchange procedures, and communication standards documented in Common Ground.

    1. CUSTODY SCHEDULE
    The parties will follow the custody schedule maintained in Common Ground, including all exchanges, holidays, and modifications agreed in writing within the app.

    2. COMMUNICATION
    The parties will use Common Ground messaging for co-parenting communication and will respond to schedule-related messages within 24 hours when reasonably possible.

    3. EXPENSES
    Shared child-related expenses will be logged in Common Ground with receipts attached when available. Reimbursement will follow the split ratio agreed by the parties.

    4. MEDICAL & SCHOOL
    Both parties will keep medical, school, and emergency information current in Common Ground and notify the other parent of urgent medical events promptly.

    5. MODIFICATIONS
    Changes to this agreement require written consent of both parties via digital signature in Common Ground.

    By signing below, each party acknowledges they have read and agree to these terms.
    """

    @discardableResult
    public static func createAgreement(
        context: ModelContext,
        family: Family,
        child: Child?,
        title: String,
        bodyText: String,
        effectiveDate: Date?,
        parentA: FamilyMember,
        parentB: FamilyMember
    ) throws -> CustodyAgreement {
        let agreement = CustodyAgreement(
            title: title,
            bodyText: bodyText,
            effectiveDate: effectiveDate
        )
        agreement.family = family
        agreement.child = child
        agreement.parentAId = parentA.id
        agreement.parentAName = parentA.displayName
        agreement.parentBId = parentB.id
        agreement.parentBName = parentB.displayName
        agreement.status = .pendingSignatures
        family.custodyAgreements.append(agreement)
        context.insert(agreement)
        try context.save()
        return agreement
    }

    public static func signAgreement(
        _ agreement: CustodyAgreement,
        member: FamilyMember,
        signatureData: Data,
        context: ModelContext
    ) throws {
        guard !signatureData.isEmpty else { throw CustodyAgreementError.emptySignature }

        if member.id == agreement.parentAId {
            guard agreement.parentASignatureData == nil else { throw CustodyAgreementError.alreadySigned }
            agreement.parentASignatureData = signatureData
            agreement.parentASignedAt = Date()
        } else if member.id == agreement.parentBId {
            guard agreement.parentBSignatureData == nil else { throw CustodyAgreementError.alreadySigned }
            agreement.parentBSignatureData = signatureData
            agreement.parentBSignedAt = Date()
        } else {
            throw CustodyAgreementError.notAuthorized
        }

        agreement.updatedAt = Date()
        if agreement.isFullySigned {
            agreement.status = .fullySigned
            agreement.documentHash = computeHash(for: agreement)
        } else {
            agreement.status = .pendingSignatures
        }
        try context.save()
    }

    public static func computeHash(for agreement: CustodyAgreement) -> String {
        var payload = agreement.bodyText
        payload += agreement.parentAName ?? ""
        payload += agreement.parentBName ?? ""
        if let a = agreement.parentASignedAt { payload += a.ISO8601Format() }
        if let b = agreement.parentBSignedAt { payload += b.ISO8601Format() }
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    #if canImport(UIKit)
    public static func generateSignedPDF(_ agreement: CustodyAgreement) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        var body = """
        \(agreement.title.uppercased())
        Status: \(agreement.status.displayName)
        Generated: \(formatter.string(from: Date()))

        \(agreement.bodyText)

        ---

        """

        if let name = agreement.parentAName, let date = agreement.parentASignedAt {
            body += "Signed by \(name) on \(formatter.string(from: date))\n"
            if let data = agreement.parentASignatureData, let image = UIImage(data: data) {
                body += "[Signature on file — \(Int(image.size.width))×\(Int(image.size.height)) px]\n"
            }
        }
        if let name = agreement.parentBName, let date = agreement.parentBSignedAt {
            body += "Signed by \(name) on \(formatter.string(from: date))\n"
        }
        if let hash = agreement.documentHash {
            body += "\nSHA-256: \(hash)\n"
        }

        let pdfData = renderPDF(title: agreement.title, body: body)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CustodyAgreement-\(agreement.id.uuidString.prefix(8)).pdf")
        try pdfData.write(to: url)
        return url
    }

    private static func renderPDF(title: String, body: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
            ]
            title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)
            body.draw(
                in: CGRect(x: 40, y: 80, width: pageRect.width - 80, height: pageRect.height - 120),
                withAttributes: bodyAttrs
            )
        }
    }
    #endif
}

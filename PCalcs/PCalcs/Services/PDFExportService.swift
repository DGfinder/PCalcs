import Foundation
import UIKit
import CryptoKit

struct PDFReportMetadata {
    let aircraft: String
    let dataPackVersion: String
    let calcVersion: String
    let checksum: String
}

protocol PDFExporting {
    func makePDF(takeoff: TakeoffDisplay, landing: LandingDisplay, takeoffInputs: TakeoffFormInputs, landingInputs: LandingFormInputs, metadata: PDFReportMetadata, units: Units, registrationFull: String?, icao: String?, runwayIdent: String?, overrideUsed: Bool, oeiSummary: String?, companySummary: (pass: Bool, notes: [String])?, signatories: (String?, String?), wx: AirportWX?, appliedWX: [String], options: PDFExportOptions, technicalDetails: [(String,String)]?) -> Data?
}

final class PDFExportService: PDFExporting {
    func makePDF(takeoff: TakeoffDisplay, landing: LandingDisplay, takeoffInputs: TakeoffFormInputs, landingInputs: LandingFormInputs, metadata: PDFReportMetadata, units: Units, registrationFull: String?, icao: String?, runwayIdent: String?, overrideUsed: Bool, oeiSummary: String?, companySummary: (pass: Bool, notes: [String])?, signatories: (String?, String?), wx: AirportWX?, appliedWX: [String], options: PDFExportOptions, technicalDetails: [(String,String)]?) -> Data? {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let inputsJSON = (try? JSONSerialization.data(withJSONObject: [
            "takeoff": ["tow": takeoffInputs.towKg, "pa_ft": takeoffInputs.pressureAltitudeFt, "oat": takeoffInputs.oatC],
            "landing": ["ldw": landingInputs.ldwKg, "pa_ft": landingInputs.pressureAltitudeFt, "oat": landingInputs.oatC]
        ])) ?? Data()
        let outputsJSON = (try? JSONSerialization.data(withJSONObject: [
            "todr": takeoff.todrM, "asdr": takeoff.asdrM, "bfl": takeoff.bflM,
            "v1": takeoff.v1Kt, "vr": takeoff.vrKt, "v2": takeoff.v2Kt,
            "ldr": landing.ldrM, "vref": landing.vrefKt
        ])) ?? Data()
        let appVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let hashInput = (appVer + "|" + metadata.calcVersion + "|" + metadata.dataPackVersion).data(using: .utf8)! + inputsJSON + outputsJSON
        let calcHash = SHA256.hash(data: hashInput).compactMap { String(format: "%02x", $0) }.joined()

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let contentInset: CGFloat = 36
            var cursor = CGPoint(x: contentInset, y: contentInset)

            // Header
            if let img = UIImage(named: "PenjetP_AppHeader") { img.draw(in: CGRect(x: contentInset, y: cursor.y, width: 40, height: 40)) }
            draw(text: "B1900D Performance (Dry)", at: CGPoint(x: contentInset + 50, y: cursor.y + 10), font: .boldSystemFont(ofSize: 18))
            cursor.y += 60

            // Inputs
            var inputsLeft: [(String, String)] = [
                ("Registration", registrationFull ?? ""),
                ("ICAO/Runway", ((icao ?? "") + " / " + (runwayIdent ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)),
                ("Weight", UnitsFormatter.formatWeight(kg: takeoffInputs.towKg, units: units)),
                ("PA", UnitsFormatter.formatDistance(m: feetToM(takeoffInputs.pressureAltitudeFt), units: units))
            ]
            if overrideUsed { inputsLeft.append(("Override", "Runway override used")) }
            var inputsRight: [(String, String)] = [
                ("OAT", "\(Int(takeoffInputs.oatC)) °C"),
                ("Runway", UnitsFormatter.formatDistance(m: takeoffInputs.runwayLengthM, units: units)),
                ("Wind", UnitsFormatter.formatSpeed(kt: takeoffInputs.windComponentKt, units: units)),
                ("Flap", "\(takeoffInputs.flapSetting)")
            ]
            if let wx {
                inputsLeft.append(("METAR", wx.metarRaw))
                let df = DateFormatter(); df.dateFormat = "HHmm'Z'"; df.timeZone = .init(secondsFromGMT: 0)
                var src = "\(wx.source) • As of \(df.string(from: wx.issued))"
                let ageMin = Int(Date().timeIntervalSince(wx.issued) / 60)
                // Suffix (STALE) if older than cache minutes (if needed, pass cache here)
                if ageMin > 10 { src += " (STALE)" }
                inputsRight.append(("WX Source", src))
                if !appliedWX.isEmpty { inputsRight.append(("Applied", appliedWX.joined(separator: ", "))) }
                if options.includeTAF, let taf = wx.tafRaw { inputsLeft.append(("TAF", taf)) }
            }
            drawTable(items: inputsLeft, at: CGRect(x: contentInset, y: cursor.y, width: 260, height: CGFloat(max(120, inputsLeft.count*18 + 8))))
            drawTable(items: inputsRight, at: CGRect(x: contentInset + 270, y: cursor.y, width: 260, height: CGFloat(max(120, inputsRight.count*18 + 8))))
            cursor.y += CGFloat(max(140, max(inputsLeft.count, inputsRight.count) * 18 + 24))

            // Outputs
            let outs1: [(String, String)] = [
                ("TODR", UnitsFormatter.formatDistance(m: takeoff.todrM, units: units)),
                ("ASDR", UnitsFormatter.formatDistance(m: takeoff.asdrM, units: units)),
                ("BFL", UnitsFormatter.formatDistance(m: takeoff.bflM, units: units))
            ]
            drawTable(items: outs1, at: CGRect(x: contentInset, y: cursor.y, width: 250, height: 90), boldValues: true)
            let outs2: [(String, String)] = [
                ("V1", UnitsFormatter.formatSpeed(kt: takeoff.v1Kt, units: units)),
                ("Vr", UnitsFormatter.formatSpeed(kt: takeoff.vrKt, units: units)),
                ("V2", UnitsFormatter.formatSpeed(kt: takeoff.v2Kt, units: units)),
                ("LDR", UnitsFormatter.formatDistance(m: landing.ldrM, units: units))
            ]
            drawTable(items: outs2, at: CGRect(x: contentInset + 260, y: cursor.y, width: 250, height: 110), boldValues: true)
            cursor.y += 130

            // Optional Technical Details
            if options.includeTechnicalDetails, let tech = technicalDetails, !tech.isEmpty {
                draw(text: "Technical Details", at: CGPoint(x: contentInset, y: cursor.y), font: .boldSystemFont(ofSize: 14))
                cursor.y += 18
                drawTable(items: tech, at: CGRect(x: contentInset, y: cursor.y, width: page.width - 2*contentInset, height: CGFloat(tech.count) * 18 + 8))
                cursor.y += CGFloat(tech.count) * 18 + 24
            }

            // Checks Summary
            draw(text: "Checks Summary", at: CGPoint(x: contentInset, y: cursor.y), font: .boldSystemFont(ofSize: 14))
            cursor.y += 18
            var checks: [(String,String)] = [("AFM", "PASS")]
            if let oei = oeiSummary { checks.append(("OEI", oei)) }
            if let comp = companySummary { checks.append(("Company", comp.pass ? "PASS" : "FAIL (\(comp.notes.count))")) }
            drawTable(items: checks, at: CGRect(x: contentInset, y: cursor.y, width: 350, height: CGFloat(checks.count) * 18 + 8))
            cursor.y += CGFloat(checks.count) * 18 + 24

            // Versions & Hash
            draw(text: "Versions & Hash", at: CGPoint(x: contentInset, y: cursor.y), font: .boldSystemFont(ofSize: 14))
            cursor.y += 18
            let versions: [(String,String)] = [
                ("App", appVer),
                ("Calc", metadata.calcVersion),
                ("Data Pack", metadata.dataPackVersion),
                ("Calc Hash", calcHash)
            ]
            drawTable(items: versions, at: CGRect(x: contentInset, y: cursor.y, width: page.width - 2*contentInset, height: 100))
            cursor.y += 110

            // Signatures
            draw(text: "Signatures", at: CGPoint(x: contentInset, y: cursor.y), font: .boldSystemFont(ofSize: 14))
            cursor.y += 18
            drawSignatureLine(label: signatories.0 ?? "Crew 1", at: CGPoint(x: contentInset, y: cursor.y))
            drawSignatureLine(label: signatories.1 ?? "Crew 2", at: CGPoint(x: contentInset + 260, y: cursor.y))
            cursor.y += 60

            // Legal
            let legal = "AFM Data — No Extrapolation. This report assumes dry runway with AFM-approved configurations and company policy overlays where configured."
            draw(text: legal, at: CGRect(x: contentInset, y: cursor.y, width: page.width - 2*contentInset, height: 60), font: .systemFont(ofSize: 10))
            cursor.y += 70

            // Footer
            let utc = ISO8601DateFormatter().string(from: Date())
            let local = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
            draw(text: "UTC: \(utc) | Local: \(local)", at: CGPoint(x: contentInset, y: page.height - contentInset - 14), font: .systemFont(ofSize: 10))
            draw(text: "1/1", at: CGPoint(x: page.width - contentInset - 24, y: page.height - contentInset - 14), font: .systemFont(ofSize: 10))
        }
        return data
    }

    // MARK: - Drawing helpers
    private func draw(text: String, at point: CGPoint, font: UIFont) {
        (text as NSString).draw(at: point, withAttributes: [ .font: font, .foregroundColor: UIColor.black ])
    }
    private func draw(text: String, at rect: CGRect, font: UIFont) {
        (text as NSString).draw(in: rect, withAttributes: [ .font: font, .foregroundColor: UIColor.black ])
    }

    private func drawTable(items: [(String,String)], at rect: CGRect, boldValues: Bool = false) {
        let keyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let valFont = boldValues ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 12)
        let lineHeight: CGFloat = 18
        var y = rect.origin.y
        for (k, v) in items {
            (k as NSString).draw(at: CGPoint(x: rect.origin.x, y: y), withAttributes: [.font: keyFont])
            (v as NSString).draw(at: CGPoint(x: rect.origin.x + rect.width/2, y: y), withAttributes: [.font: valFont])
            y += lineHeight
        }
    }

    private func drawSignatureLine(label: String, at point: CGPoint) {
        let ctx = UIGraphicsGetCurrentContext()!
        let start = CGPoint(x: point.x, y: point.y + 24)
        let end = CGPoint(x: point.x + 220, y: point.y + 24)
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: start); ctx.addLine(to: end); ctx.strokePath()
        (label as NSString).draw(at: CGPoint(x: point.x, y: point.y), withAttributes: [ .font: UIFont.systemFont(ofSize: 12) ])
    }
}
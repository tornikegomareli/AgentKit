import Foundation

/// A saved payee in the Vault demo.
struct Payee: Identifiable, Hashable {
    let id: String
    let name: String
    let iban: String
    let bankName: String
    let isVerified: Bool

    var maskedIBAN: String {
        guard iban.count > 8 else { return iban }
        let suffix = String(iban.suffix(4))
        return "••••\(suffix)"
    }
}

extension Payee {
    static let samples: [Payee] = [
        Payee(id: "PAY-001", name: "Giorgi Beridze", iban: "GE29TB7890000000003312", bankName: "TBC Bank", isVerified: true),
        Payee(id: "PAY-002", name: "Nino Kapanadze", iban: "GE60BOG0000000018745", bankName: "Bank of Georgia", isVerified: true),
        Payee(id: "PAY-003", name: "Acme Corp", iban: "GE15TB0000000000124500", bankName: "TBC Bank", isVerified: true),
        Payee(id: "PAY-004", name: "Energo-Pro Georgia", iban: "GE42LB0000000000095500", bankName: "Liberty Bank", isVerified: true),
    ]
}

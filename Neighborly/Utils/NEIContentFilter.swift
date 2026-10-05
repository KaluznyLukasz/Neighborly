//
//  NEIContentFilter.swift
//  Neighborly
//

import Foundation

// Filtr obraźliwych słów przed zapisem treści (oferty, ogłoszenia, wiadomości, profil, recenzje).
// Wytyczna App Store 1.2 wymaga filtrowania treści w aplikacjach z treściami użytkowników.
// Działa tylko po stronie klienta (bez backendu) — resztę łapią zgłoszenia i moderacja.
// Wzorce dopasowujemy do znormalizowanego tekstu: małe litery, bez znaków diakrytycznych,
// "leet" (0→o, 4→a…) zamienione na litery. Polskie wzorce to rdzenie, żeby łapać odmiany.
enum NEIContentFilter {
    static let rejectionMessage = "Neighborly doesn't allow offensive language. Edit the text and try again."

    private static let patterns: [String] = [
        // angielskie
        #"\bf+u+c+k+"#,
        #"\bm+o+t+h+e+r+f+u+c+k+"#,
        #"\b(bull)?s+h+i+t+(s|ty|head|heads)?\b"#,
        #"\bc+u+n+t+s?\b"#,
        #"\bb+i+t+c+h+(es|y)?\b"#,
        #"\bn+i+g+g+(a+|e+r+)s?\b"#,
        #"\bf+a+g+g+o+t+s?\b"#,
        #"\br+e+t+a+r+d+(s|ed)?\b"#,
        #"\bw+h+o+r+e+s?\b"#,
        #"\bs+l+u+t+s?\b"#,
        #"\ba+s+s+h+o+l+e+s?\b"#,
        #"\bd+i+c+k+h+e+a+d+s?\b"#,
        // polskie (po złożeniu ł→l i usunięciu ogonków)
        #"\bs?k+u+r+w"#,
        #"\b(s|wy|za|od|roz|prze|do|na|po|u)?p+i+e+r+d+(o+l|a+l)"#,
        #"\b(za|wy|od|po|prze|roz|do|na|u|z|w|s)?j+e+b+[aiuyn]"#,
        #"\b(ch|h)u+j"#,
        #"\bp+i+z+d"#,
        #"\bc+i+p+(a|y|e|ie|ka|ki|ko|sko)\b"#,
        #"\bd+z+i+w+k"#,
        #"\bc+i+o+t+(a|y|o|e|ami|om)\b"#,
        #"\bk+u+t+a+s"#,
        #"\bc+w+e+l(e|a|u|i|om|ami)?\b"#
    ]

    private static let regexes: [NSRegularExpression] = patterns.compactMap {
        try? NSRegularExpression(pattern: $0)
    }

    private static let leet: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s"
    ]

    /// `true`, jeśli którykolwiek z tekstów zawiera niedozwolone słowo.
    static func isObjectionable(_ texts: String?...) -> Bool {
        texts.contains { text in
            guard let text, !text.isEmpty else { return false }
            let normalized = normalize(text)
            let range = NSRange(normalized.startIndex..., in: normalized)
            return regexes.contains { $0.firstMatch(in: normalized, range: range) != nil }
        }
    }

    private static func normalize(_ text: String) -> String {
        // "ł" nie ma rozkładu Unicode, więc folding go nie ruszy
        let folded = text
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
            .lowercased()
        return String(folded.map { leet[$0] ?? $0 })
    }
}

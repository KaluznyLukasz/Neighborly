//
//  NEIUserCache.swift
//  Neighborly
//

import FirebaseFirestore

// Cache w pamięci dla dokumentów użytkowników — unika ponownego pobierania
// tego samego właściciela oferty przy każdym otwarciu jej szczegółów w tej samej sesji.
actor NEIUserCache {
    static let shared = NEIUserCache()

    private var cache: [String: NEIUser] = [:]

    func user(id: String) async -> NEIUser? {
        if let cached = cache[id] { return cached }
        let doc = try? await Firestore.firestore().collection("users").document(id).getDocument()
        let user = try? doc?.data(as: NEIUser.self)
        if let user { cache[id] = user }
        return user
    }

    func invalidate(id: String) {
        cache.removeValue(forKey: id)
    }
}

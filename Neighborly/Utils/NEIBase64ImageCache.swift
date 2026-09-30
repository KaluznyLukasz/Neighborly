//
//  NEIBase64ImageCache.swift
//  Neighborly
//

import UIKit

// Oferty/avatary trzymają obrazy jako base64 w dokumencie — bez cache każdy re-render
// widoku (np. baner znikający po 3s) dekodowałby ten sam JPEG od nowa.
enum NEIBase64ImageCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func decodedImage(base64: String) -> UIImage? {
        let key = base64 as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}

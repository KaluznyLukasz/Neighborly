//
//  NEIPhotoCropView.swift
//  Neighborly
//

import SwiftUI
import UIKit
import ImageIO

enum NEICropAspect: String, CaseIterable, Identifiable {
    case original, square, landscape, portrait, wide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:  return "Original"
        case .square:    return "Square"
        case .landscape: return "4:3"
        case .portrait:  return "3:4"
        case .wide:      return "16:9"
        }
    }

    // Stosunek szerokości do wysokości kadru
    func ratio(for imageSize: CGSize) -> CGFloat {
        switch self {
        case .original:  return imageSize.width / imageSize.height
        case .square:    return 1
        case .landscape: return 4.0 / 3.0
        case .portrait:  return 3.0 / 4.0
        case .wide:      return 16.0 / 9.0
        }
    }
}

// Ustawienia kadrowania niezależne od rozmiaru ekranu — przesunięcie liczone jako ułamek
// rozmiaru kadru, więc ten sam stan daje ten sam wynik w edytorze i przy eksporcie
struct NEIPhotoCrop: Equatable {
    var quarterTurns = 0
    var aspect: NEICropAspect = .original
    var zoom: CGFloat = 1
    var offset: CGSize = .zero

    static let maxZoom: CGFloat = 5

    var isIdentity: Bool { self == NEIPhotoCrop() }

    // Obraz wypełnia kadr przy zoom = 1; przesunięcie nie może odsłonić pustego tła
    func clamped(imageSize: CGSize) -> NEIPhotoCrop {
        var result = self
        result.zoom = min(max(zoom, 1), Self.maxZoom)
        let crop = CGSize(width: aspect.ratio(for: imageSize), height: 1)
        let displayed = Self.displayedSize(image: imageSize, crop: crop, zoom: result.zoom)
        let maxX = (displayed.width - crop.width) / 2 / crop.width
        let maxY = (displayed.height - crop.height) / 2 / crop.height
        result.offset = CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
        return result
    }

    static func displayedSize(image: CGSize, crop: CGSize, zoom: CGFloat) -> CGSize {
        let fill = max(crop.width / image.width, crop.height / image.height)
        return CGSize(width: image.width * fill * zoom, height: image.height * fill * zoom)
    }

    // Prostokąt kadru w punktach obróconego obrazu
    func cropRect(imageSize: CGSize) -> CGRect {
        let crop = CGSize(width: aspect.ratio(for: imageSize), height: 1)
        let fill = max(crop.width / imageSize.width, crop.height / imageSize.height) * zoom
        let displayed = Self.displayedSize(image: imageSize, crop: crop, zoom: zoom)
        let x = (displayed.width - crop.width) / 2 - offset.width * crop.width
        let y = (displayed.height - crop.height) / 2 - offset.height * crop.height
        return CGRect(x: x / fill, y: y / fill, width: crop.width / fill, height: crop.height / fill)
            .intersection(CGRect(origin: .zero, size: imageSize))
    }

    func apply(to image: UIImage) -> UIImage {
        let rotated = image.neiRotated(quarterTurns: quarterTurns)
        let rect = cropRect(imageSize: rotated.size).integral
        guard !rect.isEmpty else { return rotated }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { _ in
            rotated.draw(at: CGPoint(x: -rect.minX, y: -rect.minY))
        }
    }
}

extension UIImage {
    // Obrót w lewo o n × 90°, jak przycisk obrotu w Zdjęciach
    func neiRotated(quarterTurns: Int) -> UIImage {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != 0 else { return self }
        let newSize = turns.isMultiple(of: 2) ? size : CGSize(width: size.height, height: size.width)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: newSize, format: format).image { context in
            let cg = context.cgContext
            cg.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            cg.rotate(by: -CGFloat(turns) * .pi / 2)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }

    // Pomniejsza zdjęcie z galerii przez ImageIO (z uwzględnieniem orientacji EXIF), zanim trafi
    // do edytora — 48 Mpx z aparatu zjadłoby pamięć, a i tak wysyłamy najwyżej 800 px
    static func neiDownsampled(data: Data, maxPixelSize: CGFloat = 2048) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct NEIPhotoCropView: View {
    let image: UIImage
    let onDone: (UIImage, NEIPhotoCrop) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var crop: NEIPhotoCrop
    @State private var rotated: UIImage
    @State private var lastTranslation: CGSize?
    @State private var lastMagnification: CGFloat?

    private var isInteracting: Bool { lastTranslation != nil || lastMagnification != nil }

    init(image: UIImage, crop: NEIPhotoCrop, onDone: @escaping (UIImage, NEIPhotoCrop) -> Void) {
        self.image = image
        self.onDone = onDone
        _crop = State(initialValue: crop)
        _rotated = State(initialValue: image.neiRotated(quarterTurns: crop.quarterTurns))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let frame = cropFrame(in: geo.size)
                ZStack {
                    let displayed = NEIPhotoCrop.displayedSize(image: rotated.size, crop: frame, zoom: crop.zoom)
                    Image(uiImage: rotated)
                        .resizable()
                        .frame(width: displayed.width, height: displayed.height)
                        .offset(x: crop.offset.width * frame.width, y: crop.offset.height * frame.height)
                        .accessibilityIgnoresInvertColors()

                    CropMask(cropSize: frame)
                        .fill(.black.opacity(isInteracting ? 0.45 : 0.7), style: FillStyle(eoFill: true))
                        .allowsHitTesting(false)

                    CropGrid(showsThirds: isInteracting)
                        .frame(width: frame.width, height: frame.height)
                        .allowsHitTesting(false)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .contentShape(.rect)
                .gesture(dragGesture(frame: frame).simultaneously(with: magnifyGesture))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isInteracting)
                .accessibilityElement()
                .accessibilityLabel("Photo")
                .accessibilityValue("Zoom \(Int(crop.zoom * 100)) percent")
                .accessibilityHint("Swipe up or down to zoom. Use actions to move the photo.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: crop.zoom += 0.25
                    case .decrement: crop.zoom -= 0.25
                    @unknown default: break
                    }
                    settle()
                }
                .accessibilityAction(named: "Move Up") { nudge(dy: -0.1) }
                .accessibilityAction(named: "Move Down") { nudge(dy: 0.1) }
                .accessibilityAction(named: "Move Left") { nudge(dx: -0.1) }
                .accessibilityAction(named: "Move Right") { nudge(dx: 0.1) }
            }
            .background(Color.black, ignoresSafeAreaEdges: .all)
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sensoryFeedback(.selection, trigger: crop.quarterTurns)
            .sensoryFeedback(.selection, trigger: crop.aspect)
        }
        .environment(\.colorScheme, .dark)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                onDone(crop.apply(to: image), crop)
                dismiss()
            }
        }
        ToolbarItem(placement: .bottomBar) {
            Button("Rotate", systemImage: "rotate.left", action: rotate)
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            Menu {
                Picker("Aspect Ratio", selection: aspectBinding) {
                    ForEach(NEICropAspect.allCases) { aspect in
                        Text(aspect.title).tag(aspect)
                    }
                }
            } label: {
                Label("Aspect Ratio", systemImage: "aspectratio")
            }
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            Button("Reset", action: reset)
                .disabled(crop.isIdentity)
        }
    }

    // Kadr wpisany w dostępną przestrzeń z marginesem, żeby było widać zdjęcie poza nim
    private func cropFrame(in size: CGSize) -> CGSize {
        let available = CGSize(width: max(size.width - 40, 1), height: max(size.height - 64, 1))
        let ratio = crop.aspect.ratio(for: rotated.size)
        let width = min(available.width, available.height * ratio)
        return CGSize(width: width, height: width / ratio)
    }

    // Gesty liczone przyrostowo, więc przeciąganie i szczypanie działają jednocześnie bez skoków
    private func dragGesture(frame: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let last = lastTranslation ?? .zero
                crop.offset.width += (value.translation.width - last.width) / frame.width
                crop.offset.height += (value.translation.height - last.height) / frame.height
                lastTranslation = value.translation
            }
            .onEnded { _ in
                lastTranslation = nil
                if lastMagnification == nil { settle() }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let last = lastMagnification ?? 1
                let newZoom = min(max(crop.zoom * value.magnification / last, 0.7), NEIPhotoCrop.maxZoom * 1.3)
                // Przeskalowanie przesunięcia trzyma środek kadru w tym samym miejscu zdjęcia
                let factor = newZoom / crop.zoom
                crop.offset = CGSize(width: crop.offset.width * factor, height: crop.offset.height * factor)
                crop.zoom = newZoom
                lastMagnification = value.magnification
            }
            .onEnded { _ in
                lastMagnification = nil
                if lastTranslation == nil { settle() }
            }
    }

    private func settle() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) {
            crop = crop.clamped(imageSize: rotated.size)
        }
    }

    private func nudge(dx: CGFloat = 0, dy: CGFloat = 0) {
        crop.offset.width += dx
        crop.offset.height += dy
        settle()
    }

    private var aspectBinding: Binding<NEICropAspect> {
        Binding {
            crop.aspect
        } set: { aspect in
            withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) {
                crop.aspect = aspect
                crop.zoom = 1
                crop.offset = .zero
            }
        }
    }

    private func rotate() {
        crop.quarterTurns = (crop.quarterTurns + 1) % 4
        crop.zoom = 1
        crop.offset = .zero
        rotated = image.neiRotated(quarterTurns: crop.quarterTurns)
    }

    private func reset() {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) {
            crop = NEIPhotoCrop()
            rotated = image
        }
    }
}

// Przyciemnienie wszystkiego poza kadrem (wypełnienie even-odd wycina środek)
private struct CropMask: Shape {
    var cropSize: CGSize

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cropSize.width, cropSize.height) }
        set { cropSize = CGSize(width: newValue.first, height: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRect(CGRect(
            x: rect.midX - cropSize.width / 2,
            y: rect.midY - cropSize.height / 2,
            width: cropSize.width,
            height: cropSize.height
        ))
        return path
    }
}

private struct CropGrid: View {
    let showsThirds: Bool

    var body: some View {
        ZStack {
            if showsThirds {
                GridLines()
                    .stroke(.white.opacity(0.5), lineWidth: 0.5)
                    .transition(.opacity)
            }
            Rectangle()
                .stroke(.white, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

private struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for i in 1...2 {
            let x = rect.minX + rect.width * CGFloat(i) / 3
            let y = rect.minY + rect.height * CGFloat(i) / 3
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

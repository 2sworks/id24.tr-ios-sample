import SwiftUI
import IdentifySDK

// MARK: - ROI Calibration Preview

private let roiPalette: [Color] = [
    Color(red: 1.00, green: 0.84, blue: 0.00),
    Color(red: 0.00, green: 0.90, blue: 0.90),
    Color(red: 1.00, green: 0.55, blue: 0.10),
    Color(red: 0.40, green: 1.00, blue: 0.55),
    Color(red: 1.00, green: 0.40, blue: 0.75),
    Color(red: 0.65, green: 0.45, blue: 1.00),
]

// MARK: - ROICardPreview

struct ROICardPreview: View {
    let image: UIImage
    let profile: DocumentProfile

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { geo in
                    ForEach(Array(profile.fields.enumerated()), id: \.offset) { idx, field in
                        if let roi = field.regionOfInterest {
                            let r   = roi.cgRect
                            let rx  = r.minX * geo.size.width
                            let ry  = r.minY * geo.size.height
                            let rw  = r.width  * geo.size.width
                            let rh  = r.height * geo.size.height
                            let col = roiPalette[idx % roiPalette.count]

                            Rectangle()
                                .fill(col.opacity(0.14))
                                .frame(width: rw, height: rh)
                                .position(x: rx + rw / 2, y: ry + rh / 2)

                            Rectangle()
                                .stroke(col, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                                .frame(width: rw, height: rh)
                                .position(x: rx + rw / 2, y: ry + rh / 2)

                            Text(field.key)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(col)
                                .shadow(color: .black.opacity(0.85), radius: 2)
                                .position(x: rx + rw / 2, y: max(ry - 7, 8))
                        }
                    }
                }
            )
    }
}

// MARK: - ROICoordinateList

private struct ROICoordinateList: View {
    let profile: DocumentProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profile.displayName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            ForEach(Array(profile.fields.enumerated()), id: \.offset) { idx, field in
                if let r = field.regionOfInterest {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(roiPalette[idx % roiPalette.count])
                            .frame(width: 8, height: 8)
                        Text(field.key)
                            .frame(width: 100, alignment: .leading)
                        Text("x:\(fmt(r.x))  y:\(fmt(r.y))  w:\(fmt(r.width))  h:\(fmt(r.height))")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                } else {
                    HStack(spacing: 4) {
                        Circle().fill(Color.gray).frame(width: 8, height: 8)
                        Text("\(field.key)  — no ROI").foregroundColor(.gray)
                    }
                    .font(.system(size: 10, design: .monospaced))
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
    }

    private func fmt(_ v: Double) -> String { String(format: "%.2f", v) }
}

// MARK: - FullPagePreview

private struct FullPagePreview: View {
    let frontImage: UIImage
    let backImage:  UIImage

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                previewSection(title: "ÖN YÜZ — turkishIDFront",
                               image: frontImage, profile: .turkishIDFront)
                Divider().background(Color.gray.opacity(0.4))
                previewSection(title: "ARKA YÜZ — turkishIDBack",
                               image: backImage, profile: .turkishIDBack)
            }
            .padding(16)
        }
        .background(Color(white: 0.12))
    }

    private func previewSection(title: String,
                                image: UIImage,
                                profile: DocumentProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.60))

            ROICardPreview(image: image, profile: profile)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1))

            ROICoordinateList(profile: profile)
        }
    }
}

// MARK: - Previews

#Preview("Ön & Arka — ROI Kalibrasyon") {
    let front = UIImage(named: "frontID") ?? blankCard(color: .systemBlue)
    let back  = UIImage(named: "backID")  ?? blankCard(color: .systemGreen)
    return FullPagePreview(frontImage: front, backImage: back)
}

#Preview("Sadece Ön Yüz") {
    let img = UIImage(named: "realFront") ?? blankCard(color: .systemBlue)
    return ZStack {
        Color(white: 0.12).ignoresSafeArea()
        ROICardPreview(image: img, profile: .turkishIDFront)
            .padding(16)
    }
}

#Preview("Sadece Arka Yüz") {
    let img = UIImage(named: "realBack") ?? blankCard(color: .systemGreen)
    return ZStack {
        Color(white: 0.12).ignoresSafeArea()
        ROICardPreview(image: img, profile: .turkishIDBack)
            .padding(16)
    }
}

private func blankCard(color: UIColor) -> UIImage {
    let size = CGSize(width: 856, height: 540)
    UIGraphicsBeginImageContextWithOptions(size, false, 1)
    color.withAlphaComponent(0.25).setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    UIGraphicsEndImageContext()
    return img
}

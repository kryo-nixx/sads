import SwiftUI
import MapKit
import SwiftData

enum KRYMapStyle: String, CaseIterable {
    case standard = "Chuẩn"
    case hybrid = "Vệ tinh"
    case imagery = "Ảnh"
}

struct CoupleMapView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlaceModel.createdAt, order: .reverse) private var places: [PlaceModel]
    @StateObject private var locationManager = LocationManager()
    @State private var camera: MapCameraPosition = .automatic
    @State private var style: KRYMapStyle = .standard
    @State private var showSavePlace = false
    @State private var placeName = ""

    var body: some View {
        ZStack {
            mapView

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    statusCard(title: "Bạn", subtitle: locationManager.isSharing ? "Vị trí đang bật" : "Chưa bật vị trí", battery: locationManager.batteryPercent, active: locationManager.isSharing)
                    statusCard(title: "Thanh", subtitle: "Chưa có dữ liệu online", battery: nil, active: false)
                }

                if !places.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(places) { place in
                                Button {
                                    camera = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
                                } label: {
                                    Label(place.name, systemImage: place.symbol)
                                        .font(KRYTheme.rounded(11, .bold)).padding(.horizontal, 11).padding(.vertical, 8)
                                        .background(.ultraThinMaterial, in: Capsule())
                                }
                                .buttonStyle(KRYPressStyle())
                            }
                        }
                    }
                }

                Spacer()

                if locationManager.authorization == .denied || locationManager.authorization == .restricted {
                    Text("Quyền vị trí đang tắt. Bật lại trong Settings nếu muốn dùng Map.")
                        .font(KRYTheme.rounded(12, .semibold)).multilineTextAlignment(.center).padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }

                HStack(spacing: 10) {
                    circleButton(icon: locationManager.isSharing ? "location.slash.fill" : "location.fill") {
                        locationManager.isSharing ? locationManager.stop() : locationManager.requestAndStart()
                    }
                    circleButton(icon: "scope") {
                        if let loc = locationManager.location {
                            camera = .region(MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
                        }
                    }
                    circleButton(icon: "mappin.and.ellipse") { showSavePlace = true }
                        .disabled(locationManager.location == nil)
                    Menu {
                        ForEach(KRYMapStyle.allCases, id: \.self) { choice in
                            Button(choice.rawValue) { style = choice }
                        }
                    } label: {
                        Image(systemName: "square.3.layers.3d").font(.title3.bold()).frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                    }
                }

                Text("Pin/vị trí của người kia chỉ xuất hiện sau khi ghép đôi online và người đó chủ động chia sẻ.")
                    .font(.caption2.weight(.semibold)).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal, 18)
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 12)
        }
        .alert("Lưu địa điểm", isPresented: $showSavePlace) {
            TextField("Nhà, Trường, Quán quen...", text: $placeName)
            Button("Lưu") {
                guard let loc = locationManager.location else { return }
                let name = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                context.insert(PlaceModel(name: name, latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude))
                try? context.save(); placeName = ""; Haptics.success()
            }
            Button("Huỷ", role: .cancel) { placeName = "" }
        }
    }

    @ViewBuilder private var mapView: some View {
        let content = Map(position: $camera) {
            if let location = locationManager.location {
                Annotation("Bạn", coordinate: location.coordinate) { MapPersonMarker(initial: "S", battery: locationManager.batteryPercent, live: true) }
            }
            ForEach(places) { place in
                Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                    VStack(spacing: 3) {
                        Image(systemName: place.symbol).font(.title2).foregroundStyle(KRYTheme.accent).padding(8).background(.ultraThinMaterial, in: Circle())
                        Text(place.name).font(.caption2.bold()).padding(.horizontal, 7).padding(.vertical, 3).background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
        }
        switch style {
        case .standard: content.mapStyle(.standard(elevation: .realistic)).ignoresSafeArea()
        case .hybrid: content.mapStyle(.hybrid(elevation: .realistic)).ignoresSafeArea()
        case .imagery: content.mapStyle(.imagery(elevation: .realistic)).ignoresSafeArea()
        }
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3.bold()).frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
        }.buttonStyle(KRYPressStyle())
    }

    private func statusCard(title: String, subtitle: String, battery: Int?, active: Bool) -> some View {
        HStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle().fill(.white.opacity(0.92)).frame(width: 38, height: 38).overlay(Text(String(title.prefix(1))).font(.headline))
                Circle().fill(active ? .green : .gray).frame(width: 10, height: 10).overlay(Circle().stroke(.white, lineWidth: 1.5))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(KRYTheme.rounded(12, .bold))
                if let battery { HStack(spacing: 4) { BatteryGauge(percent: battery); Text("\(battery)%").font(.caption2.bold()) } }
                Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(9).frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct BatteryGauge: View {
    let percent: Int
    var body: some View {
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).stroke(.secondary, lineWidth: 1).frame(width: 22, height: 10)
                RoundedRectangle(cornerRadius: 1.5).fill(percent <= 20 ? .red : .green).frame(width: max(2, 18 * CGFloat(percent) / 100), height: 6).padding(.leading, 2)
            }
            Capsule().fill(.secondary).frame(width: 2, height: 5)
        }
    }
}

struct MapPersonMarker: View {
    let initial: String
    let battery: Int?
    let live: Bool
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(KRYTheme.accent.opacity(0.35), lineWidth: 3).frame(width: pulse ? 74 : 54, height: pulse ? 74 : 54).opacity(pulse ? 0 : 1)
                Circle().fill(.white).frame(width: 52, height: 52).overlay(Text(initial).font(KRYTheme.rounded(22, .black))).shadow(radius: 6)
            }
            if let battery {
                HStack(spacing: 3) { BatteryGauge(percent: battery); Text("\(battery)%") }
                    .font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4).background(.ultraThinMaterial, in: Capsule())
            }
        }
        .onAppear {
            guard live else { return }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

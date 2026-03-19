import SwiftUI
import WidgetKit

private let appGroupId = "group.com.dreamloop.shared"

struct DreamLoopEntry: TimelineEntry {
    let date: Date
    let eventText: String
    let mood: String
    let colorHex: String
    let sceneTag: String
    let weatherTag: String
    let timeTag: String
    let deeplink: URL
}

struct DreamLoopProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLoopEntry {
        DreamLoopEntry(
            date: Date(),
            eventText: "A glowing cave appears beyond the hills.",
            mood: "adventurous",
            colorHex: "ff6c5ce7",
            sceneTag: "cave",
            weatherTag: "clear",
            timeTag: "night",
            deeplink: URL(string: "dreamloop://story")!
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DreamLoopEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLoopEntry>) -> Void) {
        let entry = loadEntry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func loadEntry() -> DreamLoopEntry {
        let defaults = UserDefaults(suiteName: appGroupId)

        let eventText = defaults?.string(forKey: "event_text") ?? "Your world is waiting for your next choice."
        let mood = defaults?.string(forKey: "mood") ?? "cozy"
        let colorHex = defaults?.string(forKey: "character_color_hex") ?? "ff6c5ce7"
        let sceneTag = defaults?.string(forKey: "scene_tag") ?? "fields"
        let weatherTag = defaults?.string(forKey: "weather_tag") ?? "clear"
        let timeTag = defaults?.string(forKey: "time_tag") ?? "day"
        let deeplinkString = defaults?.string(forKey: "widget_url") ?? "dreamloop://story"
        let deeplink = URL(string: deeplinkString) ?? URL(string: "dreamloop://story")!

        return DreamLoopEntry(
            date: Date(),
            eventText: eventText,
            mood: mood,
            colorHex: colorHex,
            sceneTag: sceneTag,
            weatherTag: weatherTag,
            timeTag: timeTag,
            deeplink: deeplink
        )
    }
}

struct DreamLoopWidgetView: View {
    var entry: DreamLoopProvider.Entry

    var body: some View {
        Link(destination: entry.deeplink) {
            ZStack {
                LinearGradient(
                    colors: moodGradient(entry.mood),
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("DreamLoop")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))

                    PixelWorldScene(entry: entry)
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(entry.eventText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func moodGradient(_ mood: String) -> [Color] {
        switch mood {
        case "spooky":
            return [Color(red: 0.18, green: 0.10, blue: 0.09), Color(red: 0.42, green: 0.24, blue: 0.16)]
        case "mysterious":
            return [Color(red: 0.16, green: 0.16, blue: 0.36), Color(red: 0.34, green: 0.26, blue: 0.54)]
        case "adventurous":
            return [Color(red: 0.23, green: 0.24, blue: 0.60), Color(red: 0.55, green: 0.45, blue: 0.90)]
        case "magical":
            return [Color(red: 0.15, green: 0.23, blue: 0.46), Color(red: 0.31, green: 0.49, blue: 0.74)]
        default:
            return [Color(red: 0.12, green: 0.15, blue: 0.25), Color(red: 0.38, green: 0.38, blue: 0.55)]
        }
    }
}

struct PixelWorldScene: View {
    let entry: DreamLoopEntry

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bodyColor = Color(UIColor(hex: entry.colorHex) ?? .systemPurple)

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: skyColors(entry.timeTag),
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(Color.green)
                    .frame(height: h * 0.3)
                    .offset(y: h * 0.7)

                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { _ in
                        PixelCloud()
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 6)

                PixelSunMoon(timeTag: entry.timeTag)
                    .offset(x: 8, y: 6)

                SceneProp(sceneTag: entry.sceneTag)
                    .offset(x: w * 0.65, y: h * 0.44)

                WeatherLayer(weatherTag: entry.weatherTag)

                Rectangle()
                    .fill(Color(red: 0.95, green: 0.77, blue: 0.06))
                    .frame(width: 10, height: 10)
                    .offset(x: w * 0.42, y: h * 0.4)

                Rectangle()
                    .fill(Color(red: 0.20, green: 0.78, blue: 0.44))
                    .frame(width: 16, height: 14)
                    .offset(x: w * 0.78, y: h * 0.56)

                PixelFigure(color: bodyColor)
                    .offset(x: w * 0.47, y: h * 0.56)

                if hasPartner(entry.eventText) {
                    PixelFigure(color: bodyColor)
                        .offset(x: w * 0.53, y: h * 0.56)
                }
            }
        }
    }

    private func hasPartner(_ eventText: String) -> Bool {
        let t = eventText.lowercased()
        return t.contains("you and") || t.contains("together") || t.contains("companion")
    }

    private func skyColors(_ timeTag: String) -> [Color] {
        switch timeTag {
        case "night":
            return [Color(red: 0.07, green: 0.14, blue: 0.25), Color(red: 0.17, green: 0.23, blue: 0.40)]
        case "sunset":
            return [Color(red: 0.37, green: 0.17, blue: 0.43), Color(red: 0.92, green: 0.58, blue: 0.31)]
        default:
            return [Color(red: 0.24, green: 0.43, blue: 0.70), Color(red: 0.47, green: 0.66, blue: 0.89)]
        }
    }
}

struct PixelCloud: View {
    var body: some View {
        HStack(spacing: 1) {
            Rectangle().fill(Color.white.opacity(0.7)).frame(width: 4, height: 2)
            Rectangle().fill(Color.white.opacity(0.7)).frame(width: 4, height: 2)
        }
    }
}

struct PixelSunMoon: View {
    let timeTag: String
    var body: some View {
        Rectangle()
            .fill(timeTag == "night" ? Color(red: 0.85, green: 0.88, blue: 1.0) : Color(red: 0.97, green: 0.83, blue: 0.29))
            .frame(width: 8, height: 8)
    }
}

struct SceneProp: View {
    let sceneTag: String
    var body: some View {
        switch sceneTag {
        case "forest":
            Rectangle().fill(Color(red: 0.26, green: 0.64, blue: 0.28)).frame(width: 14, height: 12)
        case "village":
            Rectangle().fill(Color(red: 0.85, green: 0.78, blue: 0.64)).frame(width: 16, height: 10)
        case "camp":
            Rectangle().fill(Color(red: 0.42, green: 0.36, blue: 0.91)).frame(width: 14, height: 9)
        case "cave":
            Rectangle().fill(Color(red: 0.22, green: 0.22, blue: 0.32)).frame(width: 14, height: 10)
        case "bridge":
            Rectangle().fill(Color(red: 0.64, green: 0.46, blue: 0.32)).frame(width: 18, height: 4)
        default:
            EmptyView()
        }
    }
}

struct WeatherLayer: View {
    let weatherTag: String
    var body: some View {
        switch weatherTag {
        case "rain":
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle().fill(Color(red: 0.70, green: 0.90, blue: 0.99).opacity(0.7)).frame(width: 1, height: 4)
                }
            }
            .offset(y: 8)
        case "snow":
            HStack(spacing: 4) {
                ForEach(0..<14, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.9)).frame(width: 2, height: 2)
                }
            }
            .offset(y: 10)
        case "mist":
            Rectangle().fill(Color.gray.opacity(0.25)).frame(height: 10).offset(y: 32)
        default:
            EmptyView()
        }
    }
}

struct PixelFigure: View {
    let color: Color
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(red: 0.30, green: 0.20, blue: 0.17)).frame(width: 6, height: 2)
            Rectangle().fill(Color(red: 0.98, green: 0.82, blue: 0.70)).frame(width: 6, height: 4)
            Rectangle().fill(color).frame(width: 6, height: 6)
            HStack(spacing: 2) {
                Rectangle().fill(Color.gray).frame(width: 2, height: 4)
                Rectangle().fill(Color.gray).frame(width: 2, height: 4)
            }
        }
    }
}

@main
struct DreamLoopWidget: Widget {
    let kind: String = "DreamLoopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamLoopProvider()) { entry in
            DreamLoopWidgetView(entry: entry)
        }
        .configurationDisplayName("DreamLoop Story")
        .description("See your shared story and jump straight into the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexString.count == 6 { hexString = "FF" + hexString }
        guard hexString.count == 8, let intCode = UInt32(hexString, radix: 16) else {
            return nil
        }

        let alpha = CGFloat((intCode & 0xFF000000) >> 24) / 255.0
        let red = CGFloat((intCode & 0x00FF0000) >> 16) / 255.0
        let green = CGFloat((intCode & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(intCode & 0x000000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

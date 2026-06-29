import SwiftUI
import WidgetKit

// App Group shared with the Runner app (must match the entitlements on both
// targets and `WidgetService` in lib/services/widget_service.dart).
private let appGroupId = "group.com.korpemuhammed.mimozarandevu.app"
private let deepLink = URL(string: "mimozarandevu://calendar")

// Stil A palette — mirrors lib/theme/app_colors.dart.
private let cPrimary = Color(red: 0x2E / 255, green: 0x55 / 255, blue: 0xE6 / 255)
private let cText = Color(red: 0x16 / 255, green: 0x20 / 255, blue: 0x3A / 255)
private let cSecondary = Color(red: 0x46 / 255, green: 0x50 / 255, blue: 0x6A / 255)
private let cMuted = Color(red: 0x8A / 255, green: 0x94 / 255, blue: 0xAC / 255)
private let cSoftBlue = Color(red: 0xEA / 255, green: 0xF0 / 255, blue: 0xFF / 255)

// MARK: - Model

struct Slot: Identifiable {
  let id = UUID()
  let time: String
  let name: String
}

struct RandevuEntry: TimelineEntry {
  let date: Date
  let label: String
  let total: Int
  let remaining: Int
  let slots: [Slot]
}

// MARK: - Provider

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> RandevuEntry {
    RandevuEntry(
      date: Date(), label: "Bugün", total: 2, remaining: 2,
      slots: [Slot(time: "09:30", name: "Ahmet Yılmaz"), Slot(time: "11:00", name: "Mehmet Demir")])
  }

  func getSnapshot(in context: Context, completion: @escaping (RandevuEntry) -> Void) {
    completion(readEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RandevuEntry>) -> Void) {
    // The app pushes fresh data on every change; refresh hourly as a fallback so
    // "remaining" stays roughly current even if the app is not opened.
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
      ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [readEntry()], policy: .after(next)))
  }

  private func readEntry() -> RandevuEntry {
    let store = UserDefaults(suiteName: appGroupId)
    var slots: [Slot] = []
    let name1 = store?.string(forKey: "n1_name") ?? ""
    if !name1.isEmpty {
      slots.append(Slot(time: store?.string(forKey: "n1_time") ?? "", name: name1))
    }
    let name2 = store?.string(forKey: "n2_name") ?? ""
    if !name2.isEmpty {
      slots.append(Slot(time: store?.string(forKey: "n2_time") ?? "", name: name2))
    }
    return RandevuEntry(
      date: Date(),
      label: store?.string(forKey: "date") ?? "",
      total: store?.integer(forKey: "total") ?? 0,
      remaining: store?.integer(forKey: "remaining") ?? 0,
      slots: slots)
  }
}

// MARK: - View

struct RandevuWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      if entry.remaining > 0 {
        countRow
      } else {
        Text(entry.total > 0 ? "Bugünlük tamam 👍" : "Bugün randevu yok")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(cSecondary)
      }
      ForEach(entry.slots) { slot in
        slotRow(slot)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(14)
    .widgetBackgroundCompat(Color.white)
  }

  private var header: some View {
    HStack(spacing: 8) {
      Image(systemName: "scissors")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(cPrimary)
      Text("Berber Defteri")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(cText)
      Spacer(minLength: 4)
      Text(entry.label)
        .font(.system(size: 11))
        .foregroundColor(cMuted)
        .lineLimit(1)
    }
  }

  private var countRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text("\(entry.remaining)")
        .font(.system(size: 30, weight: .bold))
        .foregroundColor(cPrimary)
      Text("randevu kaldı")
        .font(.system(size: 12))
        .foregroundColor(cSecondary)
    }
  }

  private func slotRow(_ slot: Slot) -> some View {
    HStack(spacing: 10) {
      Text(slot.time)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(cPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(cSoftBlue)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      Text(slot.name)
        .font(.system(size: 14))
        .foregroundColor(cText)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
  }
}

extension View {
  /// `containerBackground` on iOS 17+, a plain background before it.
  @ViewBuilder
  func widgetBackgroundCompat(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      background(color)
    }
  }
}

// MARK: - Widget

@main
struct RandevuWidget: Widget {
  let kind = "RandevuWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      RandevuWidgetEntryView(entry: entry)
        .widgetURL(deepLink)
    }
    .configurationDisplayName("Berber Defteri")
    .description("Bugünün randevuları")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

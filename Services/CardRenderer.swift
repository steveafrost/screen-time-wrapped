import Foundation
import UIKit
import SwiftUI

/// Renders screen time report data into shareable PNG card images.
///
/// Uses Core Graphics to draw gradient backgrounds, stats text,
/// and fun comparisons onto a 1080×1920 pixel canvas (Instagram Story size).
class CardRenderer {

    // MARK: - Card Dimensions

    let cardSize = CGSize(width: 1080, height: 1920)
    let cornerRadius: CGFloat = 40

    // MARK: - Themes

    struct CardTheme {
        let name: String
        let gradientColors: [UIColor]
        let textColor: UIColor
        let accentColor: UIColor
        let isPro: Bool

        static let ocean = CardTheme(
            name: "Ocean",
            gradientColors: [UIColor(red: 0.05, green: 0.25, blue: 0.50, alpha: 1.0),
                             UIColor(red: 0.10, green: 0.60, blue: 0.80, alpha: 1.0)],
            textColor: .white,
            accentColor: UIColor(red: 0.40, green: 0.90, blue: 1.00, alpha: 1.0),
            isPro: false
        )

        static let midnight = CardTheme(
            name: "Midnight",
            gradientColors: [UIColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0),
                             UIColor(red: 0.20, green: 0.10, blue: 0.40, alpha: 1.0)],
            textColor: .white,
            accentColor: UIColor(red: 0.70, green: 0.40, blue: 1.00, alpha: 1.0),
            isPro: false
        )

        static let sunset = CardTheme(
            name: "Sunset",
            gradientColors: [UIColor(red: 0.80, green: 0.20, blue: 0.30, alpha: 1.0),
                             UIColor(red: 0.95, green: 0.60, blue: 0.20, alpha: 1.0)],
            textColor: .white,
            accentColor: UIColor(red: 1.00, green: 0.90, blue: 0.30, alpha: 1.0),
            isPro: true
        )

        static let forest = CardTheme(
            name: "Forest",
            gradientColors: [UIColor(red: 0.05, green: 0.30, blue: 0.15, alpha: 1.0),
                             UIColor(red: 0.20, green: 0.60, blue: 0.30, alpha: 1.0)],
            textColor: .white,
            accentColor: UIColor(red: 0.50, green: 1.00, blue: 0.50, alpha: 1.0),
            isPro: true
        )

        static let lava = CardTheme(
            name: "Lava",
            gradientColors: [UIColor(red: 0.30, green: 0.05, blue: 0.05, alpha: 1.0),
                             UIColor(red: 0.80, green: 0.20, blue: 0.05, alpha: 1.0)],
            textColor: .white,
            accentColor: UIColor(red: 1.00, green: 0.70, blue: 0.20, alpha: 1.0),
            isPro: true
        )

        static let allThemes: [CardTheme] = [.ocean, .midnight, .sunset, .forest, .lava]
        static let freeThemes: [CardTheme] = [.ocean, .midnight]
        static let proThemes: [CardTheme] = [.sunset, .forest, .lava]
    }

    // MARK: - Card Generation

    /// Render a weekly report card as a UIImage.
    func renderWeeklyCard(report: WeeklyReport, theme: CardTheme) -> UIImage? {
        return UIGraphicsImageRenderer(size: cardSize).image { context in
            let rect = CGRect(origin: .zero, size: cardSize)
            drawBackground(in: rect, theme: theme, using: context)
            drawTitle("Weekly Wrapped", in: rect, theme: theme, using: context)
            drawTotalTime(report.formattedTotalTime, subtitle: "Total Screen Time", in: rect, theme: theme, using: context, offsetY: 0.20)
            drawDailyAverage(report.formattedDailyAverage, subtitle: "Daily Average", in: rect, theme: theme, using: context, offsetY: 0.32)
            drawStatRow(pickups: report.totalPickups, notifications: report.totalNotifications, in: rect, theme: theme, using: context, offsetY: 0.44)
            drawTopApp(report.mostUsedApp, duration: report.mostUsedAppDuration, in: rect, theme: theme, using: context, offsetY: 0.56)
            drawComparison(report.comparisons.first, in: rect, theme: theme, using: context, offsetY: 0.70)
            drawFooter(in: rect, theme: theme, using: context)
        }
    }

    /// Render a monthly report card as a UIImage.
    func renderMonthlyCard(report: MonthlyReport, theme: CardTheme) -> UIImage? {
        return UIGraphicsImageRenderer(size: cardSize).image { context in
            let rect = CGRect(origin: .zero, size: cardSize)
            drawBackground(in: rect, theme: theme, using: context)
            drawTitle("Monthly Recap", in: rect, theme: theme, using: context)
            drawTotalTime(report.formattedTotalTime, subtitle: "This Month", in: rect, theme: theme, using: context, offsetY: 0.18)
            drawDailyAverage(report.formattedDailyAverage, subtitle: "Daily Average", in: rect, theme: theme, using: context, offsetY: 0.30)
            drawStatRow(pickups: report.totalPickups, notifications: report.totalNotifications, in: rect, theme: theme, using: context, offsetY: 0.42)
            drawTopApp(report.mostUsedApp, duration: report.mostUsedAppDuration, in: rect, theme: theme, using: context, offsetY: 0.54)
            if let change = report.vsPreviousMonth {
                drawChangeIndicator(change: change, in: rect, theme: theme, using: context, offsetY: 0.66)
            }
            drawComparison(report.comparisons.first, in: rect, theme: theme, using: context, offsetY: 0.78)
            drawFooter(in: rect, theme: theme, using: context)
        }
    }

    /// Render a yearly "Wrapped" card as a UIImage.
    func renderYearlyCard(report: YearlyReport, theme: CardTheme) -> UIImage? {
        return UIGraphicsImageRenderer(size: cardSize).image { context in
            let rect = CGRect(origin: .zero, size: cardSize)
            drawBackground(in: rect, theme: theme, using: context)
            drawTitle("Yearly Wrapped", in: rect, theme: theme, using: context)
            drawTotalTime(report.formattedTotalTime, subtitle: "Your Year in Screens", in: rect, theme: theme, using: context, offsetY: 0.16)
            drawDailyAverage(report.formattedDailyAverage, subtitle: "Daily Average", in: rect, theme: theme, using: context, offsetY: 0.26)
            drawStatRow(pickups: report.totalPickups, notifications: report.totalNotifications, in: rect, theme: theme, using: context, offsetY: 0.36)
            drawTextCentered("\(report.totalUniqueAppsUsed) apps used", fontSize: 32, color: theme.accentColor, rect: rect, y: rect.height * 0.46, using: context)
            drawTopApp(report.mostUsedApp, duration: report.mostUsedAppDuration, in: rect, theme: theme, using: context, offsetY: 0.54)
            drawComparison(report.comparisons.first, in: rect, theme: theme, using: context, offsetY: 0.68)
            drawTextCentered("ScreenTime Wrapped", fontSize: 24, color: theme.textColor.withAlphaComponent(0.4), rect: rect, y: rect.height * 0.92, using: context)
        }
    }

    // MARK: - Drawing Primitives

    private func drawBackground(in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext) {
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: theme.gradientColors.map { $0.cgColor } as CFArray,
            locations: [0.0, 1.0]
        )!
        context.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: rect.width, y: rect.height),
            options: []
        )

        // Subtle decorative circles
        let circleRect = CGRect(x: rect.width * 0.7, y: rect.height * 0.05, width: rect.width * 0.5, height: rect.width * 0.5)
        context.cgContext.setFillColor(theme.textColor.withAlphaComponent(0.03).cgColor)
        context.cgContext.fillEllipse(in: circleRect)

        let circleRect2 = CGRect(x: rect.width * -0.1, y: rect.height * 0.4, width: rect.width * 0.4, height: rect.width * 0.4)
        context.cgContext.setFillColor(theme.textColor.withAlphaComponent(0.03).cgColor)
        context.cgContext.fillEllipse(in: circleRect2)
    }

    private func drawTitle(_ title: String, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .heavy),
            .foregroundColor: theme.textColor,
            .kern: 2.0
        ]
        let attributed = NSAttributedString(string: title, attributes: attributes)
        let size = attributed.size()
        let point = CGPoint(x: (rect.width - size.width) / 2, y: rect.height * 0.05)
        attributed.draw(at: point)
    }

    private func drawTotalTime(_ time: String, subtitle: String, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 96, weight: .black),
            .foregroundColor: theme.textColor
        ]
        let timeAttributed = NSAttributedString(string: time, attributes: timeAttributes)
        let timeSize = timeAttributed.size()
        let timePoint = CGPoint(x: (rect.width - timeSize.width) / 2, y: rect.height * offsetY)
        timeAttributed.draw(at: timePoint)

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .medium),
            .foregroundColor: theme.textColor.withAlphaComponent(0.7),
            .kern: 1.5
        ]
        let subtitleAttributed = NSAttributedString(string: subtitle.uppercased(), attributes: subtitleAttributes)
        let subtitleSize = subtitleAttributed.size()
        let subtitlePoint = CGPoint(x: (rect.width - subtitleSize.width) / 2, y: rect.height * offsetY + timeSize.height + 8)
        subtitleAttributed.draw(at: subtitlePoint)
    }

    private func drawDailyAverage(_ average: String, subtitle: String, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        let avgAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: theme.textColor
        ]
        let avgAttributed = NSAttributedString(string: average, attributes: avgAttributes)
        let avgSize = avgAttributed.size()
        let avgPoint = CGPoint(x: (rect.width - avgSize.width) / 2, y: rect.height * offsetY)
        avgAttributed.draw(at: avgPoint)

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: theme.textColor.withAlphaComponent(0.6),
            .kern: 1.5
        ]
        let subtitleAttributed = NSAttributedString(string: subtitle.uppercased(), attributes: subtitleAttributes)
        let subtitleSize = subtitleAttributed.size()
        let subtitlePoint = CGPoint(x: (rect.width - subtitleSize.width) / 2, y: rect.height * offsetY + avgSize.height + 6)
        subtitleAttributed.draw(at: subtitlePoint)
    }

    private func drawStatRow(pickups: Int, notifications: Int, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        let baseY = rect.height * offsetY
        let statWidth = rect.width / 3
        let fontSize: CGFloat = 36

        // Pickups
        let pickupsAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize, weight: .bold), .foregroundColor: theme.textColor]
        let pickupsStr = NSAttributedString(string: "\(pickups)", attributes: pickupsAttr)
        let pickupsSize = pickupsStr.size()
        pickupsStr.draw(at: CGPoint(x: statWidth - pickupsSize.width / 2, y: baseY))

        let pickupsLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: theme.textColor.withAlphaComponent(0.6), .kern: 1.0]
        let pickupsLabel = NSAttributedString(string: "PICKUPS", attributes: pickupsLabelAttr)
        let pickupsLabelSize = pickupsLabel.size()
        pickupsLabel.draw(at: CGPoint(x: statWidth - pickupsLabelSize.width / 2, y: baseY + pickupsSize.height + 4))

        // Separator
        let sepAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize, weight: .light), .foregroundColor: theme.textColor.withAlphaComponent(0.3)]
        let sepStr = NSAttributedString(string: "|", attributes: sepAttr)
        sepStr.draw(at: CGPoint(x: statWidth * 1.5 - 8, y: baseY))

        // Notifications
        let notifAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize, weight: .bold), .foregroundColor: theme.textColor]
        let notifStr = NSAttributedString(string: "\(notifications)", attributes: notifAttr)
        let notifSize = notifStr.size()
        notifStr.draw(at: CGPoint(x: statWidth * 2 - notifSize.width / 2, y: baseY))

        let notifLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: theme.textColor.withAlphaComponent(0.6), .kern: 1.0]
        let notifLabel = NSAttributedString(string: "NOTIFICATIONS", attributes: notifLabelAttr)
        let notifLabelSize = notifLabel.size()
        notifLabel.draw(at: CGPoint(x: statWidth * 2 - notifLabelSize.width / 2, y: baseY + notifSize.height + 4))
    }

    private func drawTopApp(_ appName: String, duration: TimeInterval, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        let baseY = rect.height * offsetY
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        let durationStr = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20, weight: .medium), .foregroundColor: theme.textColor.withAlphaComponent(0.6), .kern: 1.5]
        let labelStr = NSAttributedString(string: "MOST USED APP", attributes: labelAttr)
        let labelSize = labelStr.size()
        labelStr.draw(at: CGPoint(x: (rect.width - labelSize.width) / 2, y: baseY))

        let appAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 52, weight: .heavy), .foregroundColor: theme.textColor]
        let appStr = NSAttributedString(string: appName, attributes: appAttr)
        let appSize = appStr.size()
        appStr.draw(at: CGPoint(x: (rect.width - appSize.width) / 2, y: baseY + labelSize.height + 12))

        let durationAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: theme.accentColor]
        let durationStr = NSAttributedString(string: "\(durationStr) total", attributes: durationAttr)
        let durationSize = durationStr.size()
        durationStr.draw(at: CGPoint(x: (rect.width - durationSize.width) / 2, y: baseY + labelSize.height + appSize.height + 16))
    }

    private func drawComparison(_ comparison: FunComparison?, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        guard let comparison = comparison else { return }
        let baseY = rect.height * offsetY

        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 40, weight: .black), .foregroundColor: theme.accentColor]
        let valueStr = NSAttributedString(string: "\(comparison.emoji)  \(comparison.value)", attributes: valueAttr)
        let valueSize = valueStr.size()
        valueStr.draw(at: CGPoint(x: (rect.width - valueSize.width) / 2, y: baseY))

        let detailAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20, weight: .regular), .foregroundColor: theme.textColor.withAlphaComponent(0.7)]
        let detailStr = NSAttributedString(string: comparison.detail, attributes: detailAttr)
        let detailSize = detailStr.size()
        detailStr.draw(at: CGPoint(x: (rect.width - detailSize.width) / 2, y: baseY + valueSize.height + 12))
    }

    private func drawChangeIndicator(change: MonthOverMonthChange, in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext, offsetY: CGFloat) {
        let baseY = rect.height * offsetY
        let screenTimeStr = change.screenTimeChange >= 0
            ? "+\(Int(change.screenTimeChange * 100))% screen time"
            : "\(Int(change.screenTimeChange * 100))% screen time"
        let color: UIColor = change.screenTimeChange >= 0
            ? UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            : UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)

        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: color]
        let str = NSAttributedString(string: "vs last month: \(screenTimeStr)", attributes: attr)
        let strSize = str.size()
        str.draw(at: CGPoint(x: (rect.width - strSize.width) / 2, y: baseY))
    }

    private func drawTextCentered(_ text: String, fontSize: CGFloat, color: UIColor, rect: CGRect, y: CGFloat, using context: UIGraphicsImageRendererContext) {
        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize, weight: .medium), .foregroundColor: color]
        let str = NSAttributedString(string: text, attributes: attr)
        let strSize = str.size()
        str.draw(at: CGPoint(x: (rect.width - strSize.width) / 2, y: y))
    }

    private func drawFooter(in rect: CGRect, theme: CardTheme, using context: UIGraphicsImageRendererContext) {
        let footerAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: theme.textColor.withAlphaComponent(0.3),
            .kern: 3.0
        ]
        let footerStr = NSAttributedString(string: "SCREENTIME WRAPPED", attributes: footerAttr)
        let footerSize = footerStr.size()
        footerStr.draw(at: CGPoint(x: (rect.width - footerSize.width) / 2, y: rect.height * 0.94))
    }
}

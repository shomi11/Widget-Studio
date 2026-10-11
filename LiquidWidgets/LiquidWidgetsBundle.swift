import WidgetKit
import SwiftUI

@main
struct LiquidWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Flagship customizable widget powered by SelectLiquidWidgetIntent and in-app selection
        ConfigurableLiquidGlassWidget()

        // Dedicated live HealthKit telemetry widget
        HealthVitalsLiquidWidget()

        // Dedicated world clock and atomic chrono widget
        AtomicClockLiquidWidget()

        // Dedicated interactive reminders checklist widget
        InteractiveRemindersLiquidWidget()

        // Dedicated Apple Calendar agenda widget
        CalendarEventsLiquidWidget()

        // Dedicated wake-up alarm hub widget
        AlarmsControlLiquidWidget()
    }
}

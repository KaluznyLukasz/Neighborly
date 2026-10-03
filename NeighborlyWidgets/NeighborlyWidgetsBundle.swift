//
//  NeighborlyWidgetsBundle.swift
//  NeighborlyWidgets
//

import SwiftUI
import WidgetKit

// Widżety czytają tylko migawki z App Group (Shared/NEIWidgetData.swift), które zapisuje
// aplikacja — rozszerzenie nie łączy się z Firebase
@main
struct NeighborlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NEIUpNextWidget()
        NEIAlertsWidget()
    }
}

//
//  RestTimerWidgetExtensionBundle.swift
//  RestTimerWidgetExtension
//
//  Created by Matthew Corcoran on 26/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct RestTimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        RestTimerWidgetExtension()
        RestTimerWidgetExtensionControl()
        RestTimerWidgetExtensionLiveActivity()
    }
}

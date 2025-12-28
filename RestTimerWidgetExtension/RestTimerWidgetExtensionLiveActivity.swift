//
//  RestTimerWidgetExtensionLiveActivity.swift
//  RestTimerWidgetExtension
//
//  Created by Matthew Corcoran on 26/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimerWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RestTimerWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RestTimerWidgetExtensionAttributes {
    fileprivate static var preview: RestTimerWidgetExtensionAttributes {
        RestTimerWidgetExtensionAttributes(name: "World")
    }
}

extension RestTimerWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: RestTimerWidgetExtensionAttributes.ContentState {
        RestTimerWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RestTimerWidgetExtensionAttributes.ContentState {
         RestTimerWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RestTimerWidgetExtensionAttributes.preview) {
   RestTimerWidgetExtensionLiveActivity()
} contentStates: {
    RestTimerWidgetExtensionAttributes.ContentState.smiley
    RestTimerWidgetExtensionAttributes.ContentState.starEyes
}

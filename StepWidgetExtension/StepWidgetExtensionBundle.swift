//
//  StepWidgetExtensionBundle.swift
//  StepWidgetExtension
//
//  Created by Aytac Akyildiz on 01/04/2026.
//

import WidgetKit
import SwiftUI

@main
struct StepWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StepWidgetExtension()
        StepWidgetExtensionControl()
    }
}

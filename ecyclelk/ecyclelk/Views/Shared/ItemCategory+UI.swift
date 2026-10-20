//
//  ItemCategory+UI.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import SwiftUI

extension ItemCategory {
    var symbolName: String {
        switch self {
        case .mobilePhones: return "iphone"
        case .laptops: return "laptopcomputer"
        case .batteries: return "battery.100"
        case .monitors: return "display"
        case .printers: return "printer"
        case .televisions: return "tv"
        case .cameras: return "camera"
        case . accessories : return "cable.connector"
        }
    }
    
    var tint: Color {
        switch self {
        case .mobilePhones: return Color(hex: 0xE9E3FB)
        case .laptops: return Color(hex: 0xD4EEFB)
        case .batteries: return Color(hex: 0xFDEBC8)
        case .monitors: return Color(hex: 0xDDF3E4)
        case .printers: return Color(hex: 0xFBE0E0)
        case .televisions: return Color(hex: 0xFBE0E0)
        case .cameras: return Color(hex: 0xF3E6D6)
        case .accessories: return Color(hex: 0xE6EEF0)
        }
    }
}

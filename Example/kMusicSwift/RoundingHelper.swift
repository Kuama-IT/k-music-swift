//
//  RoundingHelper.swift
//  kMusicSwift_Example
//
//  Created by kuama on 30/08/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

// Specify the decimal place to round to using an enum
public enum RoundingPrecision {
    case ones
    case tenths
    case hundredths
}

enum RoundingHelper {
    // Round to the specific decimal place
    static func preciseRound(_ value: Double,
                             precision: RoundingPrecision = .ones) -> Double
    {
        switch precision {
        case .ones:
            return round(value)
        case .tenths:
            return round(value * 10) / 10.0
        case .hundredths:
            return round(value * 100) / 100.0
        }
    }
}

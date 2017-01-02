//
//  Color.swift
//  zai
//
//  Created by 渡部郷太 on 12/28/16.
//  Copyright © 2016 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit

class Color {
    // base colors
    public static let keyColor = UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1.0) // rgba(46,125,50 ,1)
    public static let antiKeyColor = UIColor(red: 0.62, green: 0.62, blue: 0.14, alpha: 1.0) // rgba(158,157,36 ,1)
    public static let antiKeyColor2 = UIColor(red: 1.0, green: 0.56, blue: 0.0, alpha: 1.0) // rgba(255,143,0 ,1)
    
    // navigation bar
    public static let naviBarColor = Color.keyColor
    
    // tab bar
    public static let tabBarColor = Color.keyColor
    public static let tabBarItemColor = Color.antiKeyColor2
    public static let tabBarUnselectedItemColor = UIColor.black

    // baord
    public static let askQuoteColor = UIColor(red: 0.12, green: 0.53, blue: 0.90, alpha: 1.0)
    public static let bidQuoteColor = UIColor(red: 0.7, green: 0.4, blue: 0.4, alpha: 1.0)
    public static let makerButtonColor = Color .keyColor
    public static let takerButtonColor = Color.antiKeyColor2

    // positions
    public static let closedPositionColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
}

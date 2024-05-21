//
//  SDKString+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

extension String {
    
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
    
    func toMrzDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "yyMMdd"
        return dateFormatter.string(from: date ?? Date())
    }
    
    func toPassportMrzDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-dd h:m:ss Z"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "yyMMdd"
        return dateFormatter.string(from: date ?? Date())
    }
    
    func toPassportHumanDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-dd h:m:ss Z"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "dd.MM.YYYY"
        return dateFormatter.string(from: date ?? Date())
    }
    
    func mrzToNormalDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter.string(from: date ?? Date())
    }
    
}


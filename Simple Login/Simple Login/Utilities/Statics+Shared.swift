//
//  Statics+Shared.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 25/04/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import Foundation

// Shared with Share Extension
let kPreciseDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm"
    return dateFormatter
}()

func printIfDebug(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}

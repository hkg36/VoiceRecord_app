//
//  tools.swift
//  test_swift
//
//  Created by xinchen on 14-10-11.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import Foundation

func GetDateString(date:NSDate) -> String {
    let now=NSDate()
    let datesec=Int(date.timeIntervalSince1970)
    let nowsec=Int(now.timeIntervalSince1970)
    let dateday=datesec/(24*3600)
    let nowday=nowsec/(24*3600)
    let format=NSDateFormatter()
    if dateday == nowday {
        format.dateFormat="'Today' H:mm"
    }
    else if nowday - dateday == 1 {
        format.dateFormat = "'Yesterday' H:mm"
    }
    else if dateday - nowday == 1 {
        format.dateFormat = "'Tomorrow' H:mm"
    }
    else {
        format.dateFormat="MM/dd/yy H:mm"
    }
    let str=format.stringFromDate(date)
    return format.stringFromDate(date)
}
//
//  DatePickerShowup.swift
//  test_swift
//
//  Created by xinchen on 14-9-26.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit

class DatePickerShowup: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

    @IBOutlet weak var date: UIDatePicker!
    @IBOutlet weak var cancelbn: UIButton!
    @IBOutlet weak var okbn: UIButton!
    var OkCallBack:((date:NSDate!)->Void)?
    
    @IBAction func doCancle(sender: AnyObject) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDidStopSelector("closed")
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseIn)
        UIView.setAnimationDuration(0.5)
        self.alpha=0
        UIView.commitAnimations()
    }
    func closed()
    {
        self.removeFromSuperview()
    }
    func ShowUp(callback:((date:NSDate!)->Void)?=nil)
    {
        let mainwindow=UIApplication.sharedApplication().keyWindow
        self.alpha=0
        self.OkCallBack=callback
        mainwindow?.addSubview(self)
        self.date.minimumDate=NSDate()
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseOut)
        UIView.setAnimationDuration(0.5)
        self.alpha=1.0
        UIView.commitAnimations()
    }
    @IBAction func doOK(sender: AnyObject) {
        if (self.OkCallBack != nil){
            self.OkCallBack!(date: self.date.date)
        }
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDidStopSelector("closed")
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseIn)
        UIView.setAnimationDuration(0.5)
        self.alpha=0
        UIView.commitAnimations()
    }
}

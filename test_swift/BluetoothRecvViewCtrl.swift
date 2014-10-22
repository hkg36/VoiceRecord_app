//
//  BluetoothRecvViewCtrl.swift
//  test_swift
//
//  Created by xinchen on 14-10-21.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit

class BluetoothRecvView:UIView {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    func Show()
    {
        let mainwindow=UIApplication.sharedApplication().keyWindow
        self.alpha=0
        mainwindow?.addSubview(self)
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=1
            return
        })
    }
    @IBAction func close(sender: AnyObject) {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=0
            return
        }) { (Bool) -> Void in
            self.removeFromSuperview()
            return
        }
    }
}
//
//  AlertPlayView.swift
//  test_swift
//
//  Created by xinchen on 14-10-10.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit
import AVFoundation

class AlertPlayView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */
    @IBOutlet weak var title:UILabel!
    @IBOutlet weak var time:UILabel!
    var player:AVAudioPlayer?
    
    @IBAction func startPlay(sender: AnyObject)
    {
        if self.player?.playing == true {
            self.player?.stop()
        }
        self.player?.play()
    }
    @IBAction func closeView(sender: AnyObject)
    {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=0
            return
        }) { (Bool) -> Void in
            self.removeFromSuperview()
            return
        }
    }
    class func Show(id:Int)
    {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let db=appDelegate.db
        let rows = db?.query("select title,file,time from voice_log where id=?", parameters: [id])
        if rows?.count == 0 {
            return
        }
        let row=rows?[0]
        
        let avSession = AVAudioSession.sharedInstance()
        avSession.setActive(true,error:nil)
        avSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions:AVAudioSessionCategoryOptions.DefaultToSpeaker, error:nil)
        if let file = row?["file"]?.asString(){
            let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let soundFileURL = NSURL(string:docDir.stringByAppendingPathComponent(file))
            var error: NSError?
            let player = AVAudioPlayer(contentsOfURL: soundFileURL, error: &error)
            if error != nil {
                return
            }
            
            let storyboard=UIStoryboard(name:"Main", bundle: nil)
            let control=storyboard.instantiateViewControllerWithIdentifier("playWindow") as UIViewController
            let view = control.view as AlertPlayView
            view.title.text=row?["title"]?.asString()
            view.player=player
            view.time.text="\(Int(player.duration)/60):\(Int(player.duration)%60)"
            println(view.backgroundColor)
            
            view.alpha=0
            appDelegate.window?.addSubview(view)
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                view.alpha=1
                return
            }, completion: { (Bool) -> Void in
                return
            })
        }
        
    }
}

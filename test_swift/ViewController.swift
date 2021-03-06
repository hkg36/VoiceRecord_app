//
//  ViewController.swift
//  test_swift
//
//  Created by xinchen on 14-9-19.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource,AVAudioRecorderDelegate,AVAudioPlayerDelegate,
UIAlertViewDelegate,BluetoothFileRecv{

    @IBOutlet weak var mainlist: UITableView!
    var recorder:AVAudioRecorder?
    @IBOutlet weak var processbar: UISlider!
    var player:AVAudioPlayer?
    var items: [Int?]=[]
    var goSaveItem: RecordInfo?
    var timeformat=NSDateFormatter()
    var play_process_timer:NSTimer?
    var recMark:UIImageView?
    var savename:UITextField?
    @IBOutlet weak var newNotify: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressRec=UILongPressGestureRecognizer(target: self, action: "mainListLongPress:")
        longPressRec.minimumPressDuration=1.0
        mainlist.addGestureRecognizer(longPressRec)
        
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        NSFileManager.defaultManager().createDirectoryAtPath(docDir.stringByAppendingPathComponent("audio"), withIntermediateDirectories: true, attributes: nil, error: nil)
        
        let avSession = AVAudioSession.sharedInstance()
        
        avSession.setActive(true,error:nil)
        avSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions:AVAudioSessionCategoryOptions.DefaultToSpeaker, error:nil)
        avSession.requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                AVAudioSession.sharedInstance().setActive(true, error: nil)
            }else{
                println("Permission to record not granted")
            }
        })
        
        self.timeformat.dateFormat="MM/dd/yy H:mm"
        self.processbar.enabled=false
        self.processbar.continuous=true
        
        self.newNotify.enabled=false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.newNotify.enabled=true
        if (self.player?.playing==true){
            self.player?.stop()
        }
        let rows=SQLiteDB.instanse.query("select title,file,time from voice_log where id=?", parameters: [self.items[indexPath.row]!])
        if let file=rows[0]["file"]?.asString() {
            var error: NSError?
            let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let soundFileURL = NSURL(string:docDir.stringByAppendingPathComponent(file))
        
            self.player = AVAudioPlayer(contentsOfURL: soundFileURL, error: &error)
            if (self.player != nil) {
                self.player?.volume=1.0
                self.player?.delegate=self
                self.player?.prepareToPlay()
                self.player?.play()
                self.play_process_timer=NSTimer(timeInterval: 0.02, target: self, selector: "playProcessTime", userInfo: nil, repeats: true)
                NSRunLoop.mainRunLoop().addTimer(self.play_process_timer!, forMode: NSDefaultRunLoopMode)
                self.processbar.enabled=true
                if let full=self.player?.duration{
                    self.processbar.maximumValue=Float(full)
                }
            }
            else{
                println("error : \(error)")
            }
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var idlist:[Int?]=[]
        let rows=SQLiteDB.instanse.query("select id from voice_log order by id desc")
        for row in rows {
            idlist.append(row["id"]?.asInt())
        }
        self.items=idlist
        return self.items.count;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell:RecordCell = self.mainlist.dequeueReusableCellWithIdentifier("base") as RecordCell
        let rows=SQLiteDB.instanse.query("select title,file,time,duration from voice_log where id=?", parameters: [self.items[indexPath.row]!])
        let row=rows[0]
        cell.title.text = row["title"]?.asString()
        if let date=row["time"]?.asDate(){
            cell.time.text = GetDateString(date)
        }
        if let duration=row["duration"]?.asDouble(){
            let time_rep=[String(Int(duration/3600)),String(Int(duration%3600/60)),String(Int(duration%60))]
            cell.durasion.text=":".join(time_rep)
        }
        return cell
    }
    func randfilename()->String{
        var str:String=""
        let words=Array("0123456789QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm")
        for var i=0;i<20;i++ {
            let a=words[Int(arc4random_uniform(UInt32(words.count)))]
            str.append(a)
        }
        return str
    }
    @IBAction func startRecord(sender: AnyObject) {
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                AVAudioSession.sharedInstance().setActive(true, error: nil)
                
                if self.recMark == nil {
                    self.recMark=UIImageView(image: UIImage(named:"microphone"))
                    self.recMark?.backgroundColor=UIColor(white: 0.3, alpha: 0.7)
                    self.recMark?.layer.cornerRadius=10
                    self.recMark?.layer.masksToBounds=true
                }
                
                var recordSettings = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: 1,
                    AVSampleRateKey : 22050.0,
                    AVLinearPCMBitDepthKey : 16,
                    AVLinearPCMIsBigEndianKey : true,
                    AVLinearPCMIsFloatKey : true
                ]
                var error: NSError?
                let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                let fileShortName="audio/\(self.randfilename()).m4a"
                let soundFileURL = NSURL(string:docDir.stringByAppendingPathComponent(fileShortName))
                self.recorder = AVAudioRecorder(URL: soundFileURL, settings: recordSettings, error: &error)
                if let e = error {
                    let alertctl=UIAlertController(title:"error", message: e.localizedDescription, preferredStyle: .Alert)
                    alertctl.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                    self.presentViewController(alertctl, animated: true, completion: nil)
                } else {
                    if self.recMark != nil{
                        let baswindow=UIApplication.sharedApplication().delegate?.window
                        let windowsize=UIScreen.mainScreen().bounds.size
                        self.recMark?.frame=CGRect(x: (windowsize.width-170)/2,y: (windowsize.height-170)/2,width: 170,height: 170)
                        self.recMark?.alpha=0
                        baswindow??.addSubview(self.recMark!)
                        UIView.animateWithDuration(0.5,delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut , animations:{() -> Void in
                            self.recMark?.alpha=1.0
                            return
                            }
                            , completion: nil)
                    }
                    
                    var newone=RecordInfo()
                    newone.file=fileShortName
                    newone.time=NSDate()
                    self.goSaveItem=newone
                    
                    self.recorder?.delegate = self
                    //self.recorder.meteringEnabled = true
                    self.recorder?.prepareToRecord()
                    self.recorder?.record()
                }
            }else{
                let alertctl=UIAlertController(title:"error", message: "Permission to record not granted", preferredStyle: .Alert)
                alertctl.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alertctl, animated: true, completion: nil)
            }
        })
        
        
    }
    func HideRecordMark(){
        if self.recMark != nil{
            UIView.animateWithDuration(0.5,delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut , animations:{() -> Void in
                self.recMark?.alpha = 0
                return
                }
                , completion: { (value:Bool) -> Void in
                    self.recMark?.removeFromSuperview()
                    return
                }
            )
        }
    }
    @IBAction func stopRecord(sender: AnyObject) {
        self.HideRecordMark()
        self.recorder?.stop()
    }
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!,
        successfully flag: Bool) {
            println("finished recording \(flag)")
            let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            if let filename=self.goSaveItem?.file{
                let fileurl=NSURL(string:docDir.stringByAppendingPathComponent(filename))
                let player=AVAudioPlayer(contentsOfURL: fileurl, error: nil)
                if player.duration==0{
                    UIAlertView(title: "Fail", message: "File is broken,please record again", delegate: nil, cancelButtonTitle: "OK").show()
                    NSFileManager.defaultManager().removeItemAtURL(fileurl!, error: nil)
                    return
                }
                self.goSaveItem?.duration=Float(player.duration)
            }
            
            let alertctl=UIAlertController(title:"Chose a Name", message: "Input A Name And Press Save to save the record.Leave it blank and just press Save for using default name(the time).Modify the name by long press the record in future.", preferredStyle: .Alert)
            alertctl.addTextFieldWithConfigurationHandler { (textfield:UITextField!) -> Void in
                textfield.placeholder="default name is time"
                self.savename=textfield
            }
            alertctl.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler:{ (UIAlertAction)in
                let title=self.savename?.text
                self.savename=nil
                if title?.isEmpty==false{
                    self.goSaveItem?.title=title
                }
                else{
                    self.goSaveItem?.title=self.timeformat.stringFromDate(self.goSaveItem!.time!)
                }
                
                let insertid=SQLiteDB.instanse.execute("insert into voice_log(title,file,time,duration) values(?,?,?,?)", parameters:[self.goSaveItem!.title!,self.goSaveItem!.file!,self.goSaveItem!.time!,self.goSaveItem!.duration!])
                self.mainlist.beginUpdates()
                self.items.insert(Int(insertid), atIndex: 0)
                self.mainlist.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.mainlist.endUpdates()
            }))
            alertctl.addAction(UIAlertAction(title: "Give Up", style: UIAlertActionStyle.Cancel, handler:{ (UIAlertAction)in
                self.savename=nil
                let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                NSFileManager.defaultManager().removeItemAtURL(NSURL(string:docDir.stringByAppendingPathComponent(self.goSaveItem!.file!))!, error: nil)
            }))
            self.presentViewController(alertctl, animated: true, completion: {
            })
    }
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!,
        error: NSError!) {
            self.HideRecordMark()
            if let filename=self.goSaveItem?.file{
                let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                NSFileManager.defaultManager().removeItemAtURL(NSURL(string:docDir.stringByAppendingPathComponent(filename))!, error: nil)
            }
            let alertctl=UIAlertController(title:"record error", message: error.localizedDescription, preferredStyle: .Alert)
            alertctl.addAction(UIAlertAction(title: "I known", style: UIAlertActionStyle.Default, handler:{ (UIAlertAction)in
                
            }))
            self.presentViewController(alertctl, animated: true, completion:nil)
    }
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool)
    {
        self.play_process_timer?.invalidate()
        self.play_process_timer=nil
        self.processbar.enabled=false
        self.processbar.value=0
        println("finished play \(flag)")
    }
    func playProcessTime(){
        if let v=self.player?.currentTime{
            self.processbar.value=Float(v)
        }
    }
    @IBAction func changeProcess(sender: AnyObject) {
        println("touched")
        self.player?.currentTime=NSTimeInterval(self.processbar.value)
        self.play_process_timer=NSTimer(timeInterval: 0.02, target: self, selector: "playProcessTime", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.play_process_timer!, forMode: NSDefaultRunLoopMode)
        self.player?.play()
    }
    @IBAction func startChangeProcess(sender: AnyObject) {
        self.player?.pause()
        self.play_process_timer?.invalidate()
        self.play_process_timer=nil
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        return 46.0
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        switch editingStyle{
        case .Delete:
            tableView.beginUpdates()
            let deleted=self.items.removeAtIndex(indexPath.row)
            let rows=SQLiteDB.instanse.query("select title,file,time from voice_log where id=?", parameters: [deleted!])
            let row=rows[0]
            if let file=row["file"]?.asString(){
                let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                var error:NSError?
                if NSFileManager.defaultManager().removeItemAtPath(docDir.stringByAppendingPathComponent(file), error: &error) == false{
                    println("delete file fail:\(error)")
                }
            }
            SQLiteDB.instanse.execute("delete from voice_log where id=?", parameters: [deleted!])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.endUpdates()
        default:
            println("error op")
        }
    }
    @IBAction func useAsAlert(sender: AnyObject) {
        if self.mainlist.indexPathForSelectedRow() == nil{
            let alertctrl=UIAlertController(title: "not selected", message: "please select a file", preferredStyle: .Alert)
            let okAction=UIAlertAction(title: "OK", style: .Default, handler: { (action) in
            })
            alertctrl.addAction(okAction)
            self.presentViewController(alertctrl, animated: true, completion: {})
            return
        }
        let storyboard=UIStoryboard(name:"Main", bundle: nil)
        let control=storyboard.instantiateViewControllerWithIdentifier("DatePickController") as UIViewController
        let view = control.view as DatePickerShowup
        view.ShowUp({(setdate:NSDate!) in
            let calendar=NSCalendar.currentCalendar()
            let comps=calendar.components(.CalendarUnitEra | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute, fromDate: setdate)
            
            let date=calendar.dateFromComponents(comps)
            if let selected=self.mainlist.indexPathForSelectedRow() {
                let rows=SQLiteDB.instanse.query("select title,file,time from voice_log where id=?", parameters: [self.items[selected.row]!])
                let row=rows[0]
                let locnot=UILocalNotification()
                locnot.fireDate=date
                locnot.timeZone=NSTimeZone.defaultTimeZone()
                locnot.alertBody=row["title"]?.asString()
                locnot.alertAction="View"
                
                locnot.soundName="alert.caf"
                var uinfo=[NSObject : AnyObject]()
                uinfo["id"]=self.items[selected.row]
                locnot.userInfo=uinfo
                locnot.hasAction=true
                UIApplication.sharedApplication().scheduleLocalNotification(locnot)
                
                let datestring = GetDateString(date!)
                let alertctrl=UIAlertController(title: nil, message: "will be alert at \(datestring)", preferredStyle: .Alert)
                let okAction=UIAlertAction(title: "OK", style: .Default, handler: { (action) in
                })
                alertctrl.addAction(okAction)
                self.presentViewController(alertctrl, animated: true, completion: {})
            }
        })
    }
    func mainListLongPress(gestureRecognizer:UILongPressGestureRecognizer)
    {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let point=gestureRecognizer.locationInView(self.mainlist)
            if let posindexpath=self.mainlist.indexPathForRowAtPoint(point) {
                let id=self.items[posindexpath.row]
                let alertctl=UIAlertController(title:nil, message: nil, preferredStyle: .ActionSheet)
                alertctl.addAction(UIAlertAction(title: "Send by Bluetooth", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction!) -> Void in
                    let storyboard=UIStoryboard(name:"Main", bundle: nil)
                    let control=storyboard.instantiateViewControllerWithIdentifier("BluetoothSendViewCtrl").view as BluetoothSendView
                    control.Show(id!)
                    return
                }))
                alertctl.addAction(UIAlertAction(title: "Alter Name", style: .Default, handler: { (action:UIAlertAction!) -> Void in
                    let alertctl=UIAlertController(title:"Alter Name", message: "leave it blank or press Cancel for no action", preferredStyle: .Alert)
                    alertctl.addTextFieldWithConfigurationHandler { (textfield:UITextField!) -> Void in
                        textfield.placeholder="leave blank for no change"
                        self.savename=textfield
                    }
                    alertctl.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action:UIAlertAction!) -> Void in
                        let newname=self.savename!.text
                        if  newname != "" {
                            SQLiteDB.instanse.execute("update voice_log set title=?  where id=?", parameters: [newname,id!])
                            self.mainlist.beginUpdates()
                            self.mainlist.reloadRowsAtIndexPaths([posindexpath], withRowAnimation: UITableViewRowAnimation.Automatic)
                            self.mainlist.endUpdates()
                        }
                        return
                    }))
                    alertctl.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
                    self.presentViewController(alertctl, animated: true, completion: nil)
                    return
                }))
                alertctl.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
                self.presentViewController(alertctl, animated: true, completion: nil)
            }
        }
    }
    @IBAction func btStartRecv(sender: AnyObject) {
        let storyboard=UIStoryboard(name:"Main", bundle: nil)
        let control=storyboard.instantiateViewControllerWithIdentifier("BluetoothRecvViewCtrl").view as BluetoothRecvView
        control.Show(callbk: self)
    }
    func newFileRecv(title:String,time:Double,content:[UInt8])
    {
        let date=NSDate(timeIntervalSince1970: NSTimeInterval(time))
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let fileShortName="audio/\(self.randfilename()).m4a"
        let filedata=NSData(bytes: content, length: content.count)
        let fileurl=NSURL(fileURLWithPath: docDir.stringByAppendingPathComponent(fileShortName))
        if filedata.writeToURL(fileurl!, atomically: true) {
            let player=AVAudioPlayer(contentsOfURL: fileurl, error: nil)
            if player.duration != 0 {
                let insertid=SQLiteDB.instanse.execute("insert into voice_log(title,file,time,duration) values(?,?,?,?)", parameters:[title,fileShortName,date,player.duration])
                self.mainlist.beginUpdates()
                self.items.insert(Int(insertid), atIndex: 0)
                self.mainlist.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.mainlist.endUpdates()
            }
        }
    }
}


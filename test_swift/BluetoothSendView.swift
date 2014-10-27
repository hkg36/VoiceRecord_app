//
//  BluetoothSendView.swift
//  test_swift
//
//  Created by xinchen on 14-10-22.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothSendView:UIView ,CBPeripheralManagerDelegate{
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    var data:NSData?
    var filetitle:String?
    var manage:CBPeripheralManager?
    var customCharacteristic:CBMutableCharacteristic?
    var customService:CBMutableService?
    var sendCount:Int=0
    var session=[NSUUID:Int]()
    
    func Show(id:Int)
    {
        if let row = SQLiteDB.instanse.queryOne("select title,file,time from voice_log where id=?", parameters: [id]) {
            self.filetitle=row["title"]?.asString()
            self.message.text = "Preparing"
            
            var error:NSError?
            let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            var filedata:NSData?=NSData(contentsOfFile: docDir.stringByAppendingPathComponent(row["file"]!.asString()), options: NSDataReadingOptions.DataReadingMappedIfSafe, error: &error)
            var filebuffer:[UInt8]? = [UInt8](count: filedata!.length, repeatedValue: 0x00)
            filedata?.getBytes(&(filebuffer!), length: filedata!.length)
            filedata=nil
            var datadic:[String:Any]=["title":filetitle!,"time":row["time"]!.asDouble(),"data":filebuffer!]
            var packdata:[UInt8]?=Packer.pack(datadic)
            filebuffer=nil
            self.data=NSData(bytes: packdata!, length: packdata!.count)
            packdata=nil
            
            self.manage=CBPeripheralManager(delegate: self, queue: nil)
            
            let mainwindow=UIApplication.sharedApplication().keyWindow
            self.alpha=0
            mainwindow?.addSubview(self)
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.alpha=1
                return
            })
        }
    }
    @IBAction func close(sender: AnyObject) {
        if self.manage?.isAdvertising == true {
            self.manage?.stopAdvertising()
        }
        self.manage=nil
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=0
            return
            }) { (Bool) -> Void in
                self.removeFromSuperview()
                return
        }
    }
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!){
        switch peripheral.state {
        case CBPeripheralManagerState.PoweredOn:
            self.message.text = "sending \(self.filetitle!)\n\(self.sendCount) copy send"
            self.SetupService()
        case CBPeripheralManagerState.PoweredOff:
            self.message.text="Bluetooth is powered off"
        case CBPeripheralManagerState.Unauthorized:
            self.message.text="App is not authorized to use Bluetooth"
        case CBPeripheralManagerState.Unsupported:
            self.message.text="Device is not support Bluetooth"
        default:
            self.message.text="Unknow error"
        }
    }
    func SetupService(){
        self.customCharacteristic=CBMutableCharacteristic(type: GlobalStatic.characteristicUUID, properties:CBCharacteristicProperties.Read , value: nil, permissions: CBAttributePermissions.Readable)
        self.customService=CBMutableService(type: GlobalStatic.serviceUUID, primary: true)
        self.customService?.characteristics=[self.customCharacteristic!]
        self.manage?.addService(self.customService!)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!)
    {
        if (error == nil) {
            self.manage?.startAdvertising([CBAdvertisementDataLocalNameKey:"ICServer",CBAdvertisementDataServiceUUIDsKey:[GlobalStatic.serviceUUID]])
        }
    }
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!)
    {
        if error == nil {
            println("start advert")
        }else{
            self.message.text = error.localizedDescription
        }
    }
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!){
        //self.sendCount++
        //self.message.text = "sending \(self.filetitle!)\n\(self.sendCount) copy send"
        //peripheral.updateValue(self.data!, forCharacteristic: self.customCharacteristic, onSubscribedCentrals: [central!])
    }
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic!)
    {
        session.removeValueForKey(central.identifier)
    }
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!)
    {
        var offset=self.session[request.central.identifier]
        if offset==nil {
            offset=0
        }
        let datatosend=self.data?.subdataWithRange(NSMakeRange(offset!, request.central.maximumUpdateValueLength))
        offset! += datatosend!.length
        self.session[request.central.identifier]=offset
        
        request.value=datatosend
        peripheral.respondToRequest(request, withResult: CBATTError.Success)
        
        if datatosend?.length == 0{
            self.session.removeValueForKey(request.central.identifier)
        }
    }
}
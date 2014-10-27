//
//  BluetoothRecvViewCtrl.swift
//  test_swift
//
//  Created by xinchen on 14-10-21.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BluetoothFileRecv
{
    func newFileRecv(title:String,time:Double,content:[UInt8])
}

class BluetoothRecvView:UIView ,CBCentralManagerDelegate, CBPeripheralDelegate{
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    var manager:CBCentralManager?
    var peripheral:CBPeripheral?
    var callback:BluetoothFileRecv?
    var databody=NSMutableData()
    func Show(callbk:BluetoothFileRecv?=nil)
    {
        self.callback=callbk
        let mainwindow=UIApplication.sharedApplication().keyWindow
        self.alpha=0
        mainwindow?.addSubview(self)
        self.manager=CBCentralManager(delegate: self, queue: nil)
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=1
            return
        })
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    @IBAction func close(sender: AnyObject) {
        self.manager?.stopScan()
        UIApplication.sharedApplication().idleTimerDisabled = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.alpha=0
            return
        }) { (Bool) -> Void in
            self.removeFromSuperview()
            return
        }
    }
    func centralManagerDidUpdateState(central: CBCentralManager!){
        switch central.state {
        case .PoweredOn:
            self.message.text = "Searching Device ..."
            self.manager?.scanForPeripheralsWithServices([GlobalStatic.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        case .PoweredOff:
            self.message.text="Bluetooth is powered off"
        case .Unauthorized:
            self.message.text="App is not authorized to use Bluetooth"
        case .Unsupported:
            self.message.text="Device is not support Bluetooth"
        default:
            self.message.text="Unknow error"
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!){
        self.manager?.stopScan()
        if (self.peripheral != peripheral) {
            println("Connecting to peripheral \(peripheral.description)")
            self.peripheral=peripheral
            self.peripheral?.delegate=self
            // Connects to the discovered peripheral
            self.manager?.connectPeripheral(peripheral,options:nil)
        }
    }
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!){
        // Asks the peripheral to discover the service
        println("start discover service")
        self.databody.length=0
        self.peripheral?.discoverServices([GlobalStatic.serviceUUID])
    }
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!)
    {
        self.peripheral=nil
    }
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!){
        if error != nil {
            println("Error discovering service: \(error.localizedDescription)")
            return
        }
        for service in peripheral.services {
            println("Service found with UUID: \(service.UUID)")
            // Discovers the characteristics for a given service
            if service.UUID == GlobalStatic.serviceUUID {
                peripheral.discoverCharacteristics([GlobalStatic.characteristicUUID!], forService: service as CBService)
            }
        }
    }
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!)
    {
        if error != nil {
            println("Error discovering characteristic: \(error.localizedDescription)")
            return;
        }
        if service.UUID.isEqual(GlobalStatic.serviceUUID) {
            for characteristic in service.characteristics {
                if characteristic.UUID == GlobalStatic.characteristicUUID {
                    //peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                    peripheral.readValueForCharacteristic(characteristic as CBCharacteristic)
                    self.message.text = "start read file"
                }
            }
        }
    }
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!)
    {
        if error != nil {
            println("Error changing notification state: \(error.localizedDescription)")
        }
        // Exits if it's not the transfer characteristic
        if (characteristic.UUID != GlobalStatic.characteristicUUID) {
            return;
        }
        // Notification has started
        if (characteristic.isNotifying) {
            println("Notification began on \(characteristic)")
            peripheral.readValueForCharacteristic(characteristic)
        } else { // Notification has stopped
            // so disconnect from the peripheral
            println("Notification stopped on \(characteristic).  Disconnecting")
            self.manager?.cancelPeripheralConnection(self.peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!)
    {
        if error != nil{
            println(error)
            return
        }
        let data=characteristic.value
        if data.length > 0 {
            peripheral.readValueForCharacteristic(characteristic)
            self.databody.appendData(data)
            self.message.text = "read \(self.databody.length) bytes"
        }
        else {
            let recvdata=Unpacker.unPackData(self.databody) as? [String:Any]
            let titletext=recvdata?["title"] as String
            let timedouble=recvdata?["time"] as Double
            let filedata = [UInt8](recvdata?["data"] as Slice<UInt8>)
            if self.callback != nil {
                self.callback?.newFileRecv(titletext, time: timedouble, content: filedata)
            }
            self.message.text = "voice \(titletext) received"
        }
    }
    
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("CenCentalManagerDelegate didDisconnectPeripheral")
        self.manager?.scanForPeripheralsWithServices([GlobalStatic.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
}
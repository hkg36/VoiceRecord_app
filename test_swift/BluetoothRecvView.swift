//
//  BluetoothRecvViewCtrl.swift
//  test_swift
//
//  Created by xinchen on 14-10-21.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothRecvView:UIView ,CBCentralManagerDelegate, CBPeripheralDelegate{
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    var manager:CBCentralManager?
    var peripheral:CBPeripheral?
    func Show()
    {
        let mainwindow=UIApplication.sharedApplication().keyWindow
        self.alpha=0
        mainwindow?.addSubview(self)
        self.manager=CBCentralManager(delegate: self, queue: nil)
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
    func centralManagerDidUpdateState(central: CBCentralManager!){
        switch central.state {
        case .PoweredOn:
            self.message.text = "Searching Device ..."
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
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
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
        let recvdata=Unpacker.unPackData(data) as? [String:Any]
        println(recvdata?["title"])
    }

}
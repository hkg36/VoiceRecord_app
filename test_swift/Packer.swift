//
//  Packer.swift
//  SwiftPack
//
//  Created by brian on 7/1/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Foundation


public class Packer
{
    struct S{
        static let swip = UInt32(CFByteOrderGetCurrent()) == CFByteOrderLittleEndian.value
    }
    //@todo research the most effiecant array type for this
    class func pack(thing:Any) -> [UInt8]
    {
        return pack(thing, bytes: Array<UInt8>())
    }

    class func pack(srcthing:Any, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        
        if let thing = srcthing as? String
        {
            localBytes = packString(thing, bytes: bytes)
        }
        else if let thing = srcthing as? Dictionary<String, Any>
        {
            localBytes = packDictionary(thing, bytes: bytes)
        }
        else if let thing = srcthing as? Array<Any>
        {
            localBytes = packArray(thing, bytes: bytes)
        }
        else if let thing = srcthing as? Int
        {
            localBytes = packInt(thing, bytes: bytes)
        }
        else if let thing = srcthing as? UInt
        {
            localBytes = packUInt(thing, bytes: bytes)
        }
        else if let thing = srcthing as? Float
        {
            localBytes = packFloat(thing, bytes: bytes)
        }
        else if let thing = srcthing as? Double
        {
            localBytes = packDouble(thing , bytes: bytes)
        }
        else if let thing = srcthing as? [UInt8]
        {
            localBytes = packBin(thing , bytes: bytes)
        }
        else
        {
            println("Error: Can't pack type")
        }
        
        return localBytes
    }

    class func packUInt(uint:UInt, bytes:[UInt8]) -> [UInt8]
    {
        switch (uint)
        {
            case 0..<0x80:
                return packFixnum(UInt8(uint), bytes: bytes)
            
            case 0x80..<0x100:
                return packUInt8(UInt8(uint), bytes: bytes)
                
            case 0x100..<0x10000:
                return packUInt16(UInt16(uint), bytes: bytes)
                
            case 0x10000..<0x1000000:
                return packUInt32(UInt32(uint), bytes: bytes)
                
            default:
                return packUInt64(UInt64(uint), bytes: bytes)
        }
    }

    class func packFixnum(uint:UInt8, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        localBytes.append(uint);
        return localBytes
    }

    class func packUInt8(uint:UInt8, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCC);
        localBytes.append(uint);
        return localBytes
    }

    class func packUInt16(uint:UInt16, bytes:[UInt8]) -> [UInt8]
    {
        var localInt = uint
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCD);
        
        return copyBytes(uint, length: 2, bytes: localBytes)
    }

    class func packUInt32(uint:UInt32, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCE);
        
        return copyBytes(uint, length: 4, bytes: localBytes)
    }

    class func packUInt64(uint:UInt64, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCF);
        
        return copyBytes(uint, length: 8, bytes: localBytes)
    }

    class func packInt(int:Int, bytes:[UInt8]) -> [UInt8]
    {
        switch (CLongLong(int))
        {
            case 0..<0x100:
                return packInt8(Int8(int), bytes: bytes)
            
            case 0x100..<0x10000:
                return packInt16(Int16(int), bytes: bytes)
            
            case 0x10000..<0x100000000:
                return packInt32(Int32(int), bytes: bytes)

            default:
                return packInt64(Int64(int), bytes: bytes)
        }
    }

    class func packInt8(int:Int8, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xD0)
        localBytes.append(UInt8(int))
        return localBytes
    }

    class func packInt16(int:Int16, bytes:[UInt8]) -> [UInt8]
    {
        var localInt = UInt16(int)
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xD1)
        
        return copyBytes(int, length: 2, bytes: localBytes)
    }

    class func packInt32(int:Int32, bytes:[UInt8]) -> [UInt8]
    {
        var localInt:UInt32 = UInt32(int)
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xD2);
        
        return copyBytes(int, length: 4, bytes: localBytes)
    }

    class func packInt64(int:Int64, bytes:[UInt8]) -> [UInt8]
    {
        var localInt:UInt64 = UInt64(int)
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xD3)
        
        return copyBytes(int, length: 8, bytes: localBytes)
    }

    class func packFloat(float:Float, bytes:[UInt8]) -> [UInt8]
    {
        var localFloat = float
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCA)
        
        return copyBytes(localFloat, length: 4, bytes: localBytes)
    }

    class func packDouble(float:Double, bytes:[UInt8]) -> [UInt8]
    {
        var localFloat = float
        var localBytes:Array<UInt8> = bytes
        localBytes.append(0xCB)
        
        return copyBytes(localFloat, length: 8, bytes: localBytes)
    }

    class func packBin(bin:[UInt8], bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        let length = bin.count
        if (length < 0x100)
        {
            localBytes.append(UInt8(0xC4))
        }
        else if (length < 0x10000)
        {
            localBytes.append(UInt8(0xC5))
        }
        else
        {
            localBytes.append(UInt8(0xC6))
        }
        
        localBytes += lengthBytes(length)
        localBytes += bin
        
        return localBytes
    }

    class func packString(string:String, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        
        var stringBuff = [UInt8]()
        stringBuff += string.utf8

        var length = stringBuff.count
        if (length < 0x20)
        {
            localBytes.append(UInt8(0xA0 | UInt8(length)))
        }
        else
        {
            if (length < 0x100)
            {
                localBytes.append(UInt8(0xD9))
            }
            else if (length < 0x10000)
            {
                localBytes.append(UInt8(0xDA))
            }
            else
            {
                localBytes.append(UInt8(0xDB))
            }
            
            localBytes += lengthBytes(length)
        }
        
        localBytes += stringBuff
        
        return localBytes
    }

    class func packArray(array:Array<Any>, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        var items = array.count
        if (items < 0x10)
        {
            localBytes.append(UInt8(0x90 | UInt8(items)))
        }
        else
        {
            if (items < 0x10000)
            {
                localBytes.append(UInt8(0xDC))
            }
            else
            {
                localBytes.append(UInt8(0xDD))
            }
            
            localBytes += lengthBytes(items)
        }

        for item in array
        {
           localBytes = pack(item, bytes: localBytes)
        }
        
        return localBytes
    }

    class func packDictionary(dict:Dictionary<String, Any>, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        var elements = dict.count
        if (elements < 0x10)
        {
            localBytes.append(UInt8(0x80 | UInt8(elements)))
        }
        else
        {
            if (elements < 0x100)
            {
                localBytes.append(UInt8(0xDE))
            }
            else
            {
                localBytes.append(UInt8(0xDF))
            }
            localBytes += lengthBytes(elements)
        }

        for (key, value) in dict
        {
            localBytes = pack(key, bytes: localBytes)
            localBytes = pack(value, bytes: localBytes)
        }
        
        return localBytes
    }

    class func lengthBytes(lengthIn:Int) -> [UInt8]
    {
        switch (CLongLong(lengthIn))
        {
        case 0..<0x100:
            return [UInt8(lengthIn)]
        case 0x100..<0x10000:
            var v=UInt16(lengthIn).bigEndian
            var lengthBytes = [UInt8](count:2, repeatedValue:0)
            memcpy(&lengthBytes, &v, 2)
            return lengthBytes
        case 0x10000..<0x100000000:
            var v=UInt32(lengthIn).bigEndian
            var lengthBytes = [UInt8](count:4, repeatedValue:0)
            memcpy(&lengthBytes, &v, 4)
            return lengthBytes
        default:
            error("Unknown length")
            return []
        }
    }

    class func copyBytes<T>(value:T, length:Int, bytes:[UInt8]) -> [UInt8]
    {
        var localValue = value
        var localBytes:Array<UInt8> = bytes
        var intBytes:Array<UInt8> = Array<UInt8>(count:length, repeatedValue:0)
        memcpy(&intBytes, &localValue, UInt(length))
        if S.swip{
            intBytes=intBytes.reverse()
        }
        localBytes += intBytes
        
        return localBytes
    }
}
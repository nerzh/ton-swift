import Foundation

/*
 Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L147
 message$_ {X:Type} info:CommonMsgInfo
                    init:(Maybe (Either StateInit ^StateInit))
                    body:(Either X ^X) = Message X;
 */

public struct Message: Readable, Writable {
    public let info: CommonMessageInfo
    public let stateInit: StateInit?
    public let body: Cell
    
    public static func readFrom(slice: Slice) throws -> Message {
        let info = try CommonMessageInfo.readFrom(slice: slice)
        
        var stateInit: StateInit? = nil
        if try slice.bits.loadBit() {
            if !(try slice.bits.loadBit()) {
                stateInit = try StateInit.readFrom(slice: slice)
            } else {
                stateInit = try StateInit.readFrom(slice: try slice.loadRef().beginParse())
            }
        }
        
        var body: Cell
        if try slice.bits.loadBit() {
            body = try slice.loadRef()
        } else {
            body = try slice.loadRemainder()
        }
        
        return Message(info: info, stateInit: stateInit, body: body)
    }
    
    public func writeTo(builder: Builder) throws {
        try builder.store(info)
        
        if let stateInit {
            try builder.bits.write(bit: 1)
            let initCell = try Builder().store(stateInit)
            
            // check if we fit the cell inline with 2 bits for the stateinit and the body
            if let space = builder.fit(initCell.metrics), space.bitsCount >= 2 {
                try builder.bits.write(bit: 0)
                try builder.store(initCell)
            } else {
                try builder.bits.write(bit: 1)
                try builder.storeRef(cell: initCell)
            }
        } else {
            try builder.bits.write(bit:0)
        }
        
        if let space = builder.fit(body.metrics), space.bitsCount >= 1 {
            try builder.bits.write(bit: 0)
            try builder.store(body.asBuilder())
        } else {
            try builder.bits.write(bit: 1)
            try builder.storeRef(cell: body)
        }
    }
}

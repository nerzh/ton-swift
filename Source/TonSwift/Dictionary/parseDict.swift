import Foundation
import BigInt

func doParse<V>(prefix: String, slice: Slice, n: Int, res: inout [BitString: V], extractor: (Slice) throws -> V) throws {
    // Reading label
    let lb0 = try slice.bits.loadBit() ? 1 : 0
    var prefixLength: Int = 0
    var pp = prefix
    
    if lb0 == 0 {
        // Short label detected
        
        // Read
        prefixLength = try Unary.readFrom(slice: slice).value
        
        // Read prefix
        for _ in 0..<prefixLength {
            pp += try slice.bits.loadBit() ? "1" : "0"
        }
    } else {
        let lb1 = try slice.bits.loadBit() ? 1 : 0
        if lb1 == 0 {
            // Long label detected
            prefixLength = Int(try slice.bits.loadUint(bits: Int(ceil(log2(Double(n + 1))))))
            for _ in 0..<prefixLength {
                pp += try slice.bits.loadBit() ? "1" : "0"
            }
        } else {
            // Same label detected
            let bit = try slice.bits.loadBit() ? "1" : "0"
            prefixLength = Int(try slice.bits.loadUint(bits: Int(ceil(log2(Double(n + 1))))))
            for _ in 0..<prefixLength {
                pp += bit
            }
        }
    }
    
    if n - prefixLength == 0 {
        // TODO: replace this with true original bitstring w/o parsing
        res[try! BitString(binaryString: pp)] = try extractor(slice)
    } else {
        let left = try slice.loadRef()
        let right = try slice.loadRef()
        // NOTE: Left and right branches are implicitly contain prefixes '0' and '1'
        if !left.isExotic {
            try doParse(prefix: pp + "0", slice: left.beginParse(), n: n - prefixLength - 1, res: &res, extractor: extractor)
        }
        if !right.isExotic {
            try doParse(prefix: pp + "1", slice: right.beginParse(), n: n - prefixLength - 1, res: &res, extractor: extractor)
        }
    }
}

func parseDict<V>(sc: Slice?, keySize: Int, extractor: @escaping (Slice) throws -> V) throws -> [BitString: V] {
    var res = [BitString: V]()
    if let sc = sc {
        try doParse(prefix: "", slice: sc, n: keySize, res: &res, extractor: extractor)
    }
    
    return res
}

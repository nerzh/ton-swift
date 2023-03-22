import XCTest
@testable import TonSwift

final class BuilderTest: XCTestCase {

    func testBuilder() throws {
        // should read uints from builder
        for _ in 0..<1000 {
            let a = UInt64.random(in: 0..<10000000)
            let b = UInt64.random(in: 0..<10000000)
            let builder = Builder()
            try builder.storeUint(a, bits: 48)
            try builder.storeUint(b, bits: 48)
            
            let bits = try builder.endCell().bits
            let reader = BitReader(bits: bits)
            XCTAssertEqual(try reader.preloadUint(bits: 48), a)
            XCTAssertEqual(try reader.loadUint(bits: 48), a)
            XCTAssertEqual(try reader.preloadUint(bits: 48), b)
            XCTAssertEqual(try reader.loadUint(bits: 48), b)
        }
        
        // TODO: - create tests for int, varUint, varInt, coins, address, external address
    }
}

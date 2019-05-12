//
//  PointerArithmeticsImplimentation.swift
//  scrypt
//
//  Created by Alex Vlasov on 02/10/2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import CryptoSwift

enum ScryptError: Error {
    case nIsTooLarge
    case rIsTooLarge
    case nMustBeAPowerOf2GreaterThan1
}
/// Implementation of the scrypt key derivation function.
public class ScryptPA {
    enum Error: Swift.Error {
        case invalidPassword
        case invalidSalt
    }
    
    /// Configuration parameters.
    private let salt: Array<UInt8> // S
    private let password: Array<UInt8>
    fileprivate let blocksize: Int // 128 * r
    private let dkLen: Int
    private let N: Int
    private let r: Int
    private let p: Int
    
    public init(password: Array<UInt8>, salt: Array<UInt8>, dkLen: Int, N: Int, r: Int, p: Int) throws {
        precondition(dkLen > 0)
        precondition(N > 0)
        precondition(r > 0)
        precondition(p > 0)
        
        guard !(N < 2 || (N & (N - 1)) != 0) else { throw ScryptError.nMustBeAPowerOf2GreaterThan1 }
        
        guard N <= .max / 128 / r else { throw ScryptError.nIsTooLarge }
        guard r <= .max / 128 / p else { throw ScryptError.rIsTooLarge }
        
        self.blocksize = 128 * r
        self.N = N
        self.r = r
        self.p = p
        self.password = password
        self.salt = salt
        self.dkLen = dkLen
    }
    
    private var salsaBlock = UnsafeMutableRawPointer.allocate(byteCount: 64, alignment: 64)
    
    deinit {
        salsaBlock.deallocate()
    }
    
    /// Runs the key derivation function with a specific password.
    public func calculate() throws -> [UInt8] {
        // Allocate memory.
        let B = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * p, alignment: 64)
        let XY = UnsafeMutableRawPointer.allocate(byteCount: 256 * r + 64, alignment: 64)
        let V = UnsafeMutableRawPointer.allocate(byteCount: 128 * r * N, alignment: 64)
        
        // Deallocate memory when done
        defer {
            B.deallocate()
            XY.deallocate()
            V.deallocate()
        }
        
        /* 1: (B_0 ... B_{p-1}) <-- PBKDF2(P, S, 1, p * MFLen) */
        let barray = try PKCS5.PBKDF2(password: password, salt: [UInt8](salt), iterations: 1, keyLength: p * 128 * r, variant: .sha256).calculate()
        barray.withUnsafeBytes { p in
            B.copyMemory(from: p.baseAddress!, byteCount: barray.count)
        }
        
        /* 2: for i = 0 to p - 1 do */
        for i in 0 ..< p {
            /* 3: B_i <-- MF(B_i, N) */
            smix(B + i * 128 * r, V.assumingMemoryBound(to: UInt32.self), XY.assumingMemoryBound(to: UInt32.self))
        }
        
        /* 5: DK <-- PBKDF2(P, B, 1, dkLen) */
        let pointer = B.assumingMemoryBound(to: UInt8.self)
        let bufferPointer = UnsafeBufferPointer(start: pointer, count: p * 128 * r)
        let block = [UInt8](bufferPointer)
        return try PKCS5.PBKDF2(password: password, salt: block, iterations: 1, keyLength: dkLen, variant: .sha256).calculate()
    }
    
    /// Computes `B = SMix_r(B, N)`.
    ///
    /// The input `block` must be `128*r` bytes in length; the temporary storage `v` must be `128*r*n` bytes in length;
    /// the temporary storage `xy` must be `256*r + 64` bytes in length. The arrays `block`, `v`, and `xy` must be
    /// aligned to a multiple of 64 bytes.
    @inline(__always) private func smix(_ block: UnsafeMutableRawPointer, _ v: UnsafeMutablePointer<UInt32>, _ xy: UnsafeMutablePointer<UInt32>) {
        let X = xy
        let Y = xy + 32 * r
        let Z = xy + 64 * r
        
                /* 1: X <-- B */
        let typedBlock = block.assumingMemoryBound(to: UInt32.self)
        X.assign(from: typedBlock, count: 32*r)
        
        /* 2: for i = 0 to N - 1 do */
        for i in stride(from: 0, to: N, by: 2) {
            /* 3: V_i <-- X */
            UnsafeMutableRawPointer(v + i * (32 * r)).copyMemory(from: X, byteCount: 128 * r)
            
            /* 4: X <-- H(X) */
            blockMixSalsa8(X, Y, Z)
            
            /* 3: V_i <-- X */
            UnsafeMutableRawPointer(v + (i + 1) * (32 * r)).copyMemory(from: Y, byteCount: 128 * r)
            
            /* 4: X <-- H(X) */
            blockMixSalsa8(Y, X, Z)
        }
        
        /* 6: for i = 0 to N - 1 do */
        for _ in stride(from: 0, to: N, by: 2) {
            /* 7: j <-- Integerify(X) mod N */
            var j = Int(integerify(X) & UInt64(N - 1))
            
            /* 8: X <-- H(X \xor V_j) */
            blockXor(X, v + j * 32 * r, 128 * r)
            blockMixSalsa8(X, Y, Z)
            
            /* 7: j <-- Integerify(X) mod N */
            j = Int(integerify(Y) & UInt64(N - 1))
            
            /* 8: X <-- H(X \xor V_j) */
            blockXor(Y, v + j * 32 * r, 128 * r)
            blockMixSalsa8(Y, X, Z)
        }
        
        /* 10: B' <-- X */
        for k in 0 ..< 32 * r {
            UnsafeMutableRawPointer(block + 4 * k).storeBytes(of: X[k], as: UInt32.self)
        }
    }
    
    /// Returns the result of parsing `B_{2r-1}` as a little-endian integer.
    @inline(__always) private func integerify(_ block: UnsafeRawPointer) -> UInt64 {
        let bi = block + (2 * r - 1) * 64
        return bi.load(as: UInt64.self).littleEndian
    }
    
    /// Compute `bout = BlockMix_{salsa20/8, r}(bin)`.
    ///
    /// The input `bin` must be `128*r` bytes in length; the output `bout` must also be the same size. The temporary
    /// space `x` must be 64 bytes.
    private func blockMixSalsa8(_ bin: UnsafePointer<UInt32>, _ bout: UnsafeMutablePointer<UInt32>, _ x: UnsafeMutablePointer<UInt32>) {
        /* 1: X <-- B_{2r - 1} */
        UnsafeMutableRawPointer(x).copyMemory(from: bin + (2 * r - 1) * 16, byteCount: 64)
        
        /* 2: for i = 0 to 2r - 1 do */
        for i in stride(from: 0, to: 2 * r, by: 2) {
            /* 3: X <-- H(X \xor B_i) */
            blockXor(x, bin + i * 16, 64)
//            salsa20_8(x)
            salsa20_8_typed(x)
            
            /* 4: Y_i <-- X */
            /* 6: B' <-- (Y_0, Y_2 ... Y_{2r-2}, Y_1, Y_3 ... Y_{2r-1}) */
            UnsafeMutableRawPointer(bout + i * 8).copyMemory(from: x, byteCount: 64)
            
            /* 3: X <-- H(X \xor B_i) */
            blockXor(x, bin + i * 16 + 16, 64)
//            salsa20_8(x)
            salsa20_8_typed(x)
            
            /* 4: Y_i <-- X */
            /* 6: B' <-- (Y_0, Y_2 ... Y_{2r-2}, Y_1, Y_3 ... Y_{2r-1}) */
            UnsafeMutableRawPointer(bout + i * 8 + r * 16).copyMemory(from: x, byteCount: 64)
        }
    }
    
    /// Applies the salsa20/8 core to the provided block.
    private func salsa20_8(_ block: UnsafeMutablePointer<UInt32>) {
        salsaBlock.copyMemory(from: UnsafeRawPointer(block), byteCount: 64)
        
        for _ in stride(from: 0, to: 8, by: 2) {
            RMix(salsaBlock, rotation: 7, 0, 12, 4)
            RMix(salsaBlock, rotation: 9, 4, 0, 8)
            RMix(salsaBlock, rotation: 13, 8, 4, 12)
            RMix(salsaBlock, rotation: 18, 12, 8, 0)
            
            RMix(salsaBlock, rotation: 7, 5, 1, 9)
            RMix(salsaBlock, rotation: 9, 9, 5, 13)
            RMix(salsaBlock, rotation: 13, 13, 9, 1)
            RMix(salsaBlock, rotation: 18, 1, 13, 5)
            
            RMix(salsaBlock, rotation: 7, 10, 6, 14)
            RMix(salsaBlock, rotation: 9, 14, 10, 2)
            RMix(salsaBlock, rotation: 13, 2, 14, 6)
            RMix(salsaBlock, rotation: 18, 6, 2, 10)
            
            RMix(salsaBlock, rotation: 7, 15, 11, 3)
            RMix(salsaBlock, rotation: 9, 3, 15, 7)
            RMix(salsaBlock, rotation: 13, 7, 3, 11)
            RMix(salsaBlock, rotation: 18, 11, 7, 15)
            
            RMix(salsaBlock, rotation: 7, 0, 3, 1)
            RMix(salsaBlock, rotation: 9, 1, 0, 2)
            RMix(salsaBlock, rotation: 13, 2, 1, 3)
            RMix(salsaBlock, rotation: 18, 3, 2, 4)
            
            RMix(salsaBlock, rotation: 7, 5, 4, 6)
            RMix(salsaBlock, rotation: 9, 6, 5, 7)
            RMix(salsaBlock, rotation: 13, 7, 6, 4)
            RMix(salsaBlock, rotation: 18, 4, 7, 5)
            
            RMix(salsaBlock, rotation: 7, 10, 9, 11)
            RMix(salsaBlock, rotation: 9, 11, 10, 8)
            RMix(salsaBlock, rotation: 13, 8, 11, 9)
            RMix(salsaBlock, rotation: 18, 9, 8, 10)
            
            RMix(salsaBlock, rotation: 7, 15, 14, 12)
            RMix(salsaBlock, rotation: 9, 12, 15, 13)
            RMix(salsaBlock, rotation: 13, 13, 12, 14)
            RMix(salsaBlock, rotation: 18, 14, 13, 15)
        }
        for i in 0 ..< 16 {
            block[i] = block[i] &+ salsaBlock.load(fromByteOffset: i*4, as: UInt32.self)
        }
    }
    
    @inline(__always) private func salsa20_8_typed(_ block: UnsafeMutablePointer<UInt32>) {
        
        salsaBlock.copyMemory(from: UnsafeRawPointer(block), byteCount: 64)
        let salsaBlockTyped = salsaBlock.assumingMemoryBound(to: UInt32.self)
        
        for _ in stride(from: 0, to: 8, by: 2) {
            
            salsaBlockTyped[ 4] ^= R(salsaBlockTyped[ 0] &+ salsaBlockTyped[12], 7)
            salsaBlockTyped[ 8] ^= R(salsaBlockTyped[ 4] &+ salsaBlockTyped[ 0], 9)
            salsaBlockTyped[12] ^= R(salsaBlockTyped[ 8] &+ salsaBlockTyped[ 4],13)
            salsaBlockTyped[ 0] ^= R(salsaBlockTyped[12] &+ salsaBlockTyped[ 8],18)
            
            salsaBlockTyped[ 9] ^= R(salsaBlockTyped[ 5] &+ salsaBlockTyped[ 1], 7)
            salsaBlockTyped[13] ^= R(salsaBlockTyped[ 9] &+ salsaBlockTyped[ 5], 9)
            salsaBlockTyped[ 1] ^= R(salsaBlockTyped[13] &+ salsaBlockTyped[ 9],13)
            salsaBlockTyped[ 5] ^= R(salsaBlockTyped[ 1] &+ salsaBlockTyped[13],18)
            
            salsaBlockTyped[14] ^= R(salsaBlockTyped[10] &+ salsaBlockTyped[ 6], 7)
            salsaBlockTyped[ 2] ^= R(salsaBlockTyped[14] &+ salsaBlockTyped[10], 9)
            salsaBlockTyped[ 6] ^= R(salsaBlockTyped[ 2] &+ salsaBlockTyped[14],13)
            salsaBlockTyped[10] ^= R(salsaBlockTyped[ 6] &+ salsaBlockTyped[ 2],18)
            
            salsaBlockTyped[ 3] ^= R(salsaBlockTyped[15] &+ salsaBlockTyped[11], 7)
            salsaBlockTyped[ 7] ^= R(salsaBlockTyped[ 3] &+ salsaBlockTyped[15], 9)
            salsaBlockTyped[11] ^= R(salsaBlockTyped[ 7] &+ salsaBlockTyped[ 3],13)
            salsaBlockTyped[15] ^= R(salsaBlockTyped[11] &+ salsaBlockTyped[ 7],18)
            
            salsaBlockTyped[ 1] ^= R(salsaBlockTyped[ 0] &+ salsaBlockTyped[ 3], 7)
            salsaBlockTyped[ 2] ^= R(salsaBlockTyped[ 1] &+ salsaBlockTyped[ 0], 9)
            salsaBlockTyped[ 3] ^= R(salsaBlockTyped[ 2] &+ salsaBlockTyped[ 1],13)
            salsaBlockTyped[ 0] ^= R(salsaBlockTyped[ 3] &+ salsaBlockTyped[ 2],18)
            
            salsaBlockTyped[ 6] ^= R(salsaBlockTyped[ 5] &+ salsaBlockTyped[ 4], 7)
            salsaBlockTyped[ 7] ^= R(salsaBlockTyped[ 6] &+ salsaBlockTyped[ 5], 9)
            salsaBlockTyped[ 4] ^= R(salsaBlockTyped[ 7] &+ salsaBlockTyped[ 6],13)
            salsaBlockTyped[ 5] ^= R(salsaBlockTyped[ 4] &+ salsaBlockTyped[ 7],18)
            
            salsaBlockTyped[11] ^= R(salsaBlockTyped[10] &+ salsaBlockTyped[ 9], 7)
            salsaBlockTyped[ 8] ^= R(salsaBlockTyped[11] &+ salsaBlockTyped[10], 9)
            salsaBlockTyped[ 9] ^= R(salsaBlockTyped[ 8] &+ salsaBlockTyped[11],13)
            salsaBlockTyped[10] ^= R(salsaBlockTyped[ 9] &+ salsaBlockTyped[ 8],18)
            
            salsaBlockTyped[12] ^= R(salsaBlockTyped[15] &+ salsaBlockTyped[14], 7)
            salsaBlockTyped[13] ^= R(salsaBlockTyped[12] &+ salsaBlockTyped[15], 9)
            salsaBlockTyped[14] ^= R(salsaBlockTyped[13] &+ salsaBlockTyped[12],13)
            salsaBlockTyped[15] ^= R(salsaBlockTyped[14] &+ salsaBlockTyped[13],18)
        }
        for i in 0 ..< 16 {
            block[i] = block[i] &+ salsaBlockTyped[i]
        }
    }
}


@inline(__always) private func blockXor(_ dest: UnsafeMutableRawPointer, _ src: UnsafeRawPointer, _ len: Int) {
    let D = dest.assumingMemoryBound(to: UInt64.self)
    let S = src.assumingMemoryBound(to: UInt64.self)
    let L = len / MemoryLayout<UInt64>.size
    
    for i in 0 ..< L {
        D[i] ^= S[i]
    }
}

@inline(__always) private func RMix(_ block: UnsafeMutableRawPointer, rotation: Int, _ aIndex: Int, _ bIndex: Int, _ destIndex: Int) {
    let a = block.load(fromByteOffset: aIndex*4, as: UInt32.self)
    let b = block.load(fromByteOffset: bIndex*4, as: UInt32.self)
    let c = a &+ b
    let result = (c << rotation) | (c >> (32 - rotation))
    let destination = block.load(fromByteOffset: destIndex*4, as: UInt32.self)
    block.storeBytes(of: result ^ destination, toByteOffset: destIndex*4, as: UInt32.self)
}


@inline(__always)  private func R(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return (a << b) | (a >> (32 - b))
}

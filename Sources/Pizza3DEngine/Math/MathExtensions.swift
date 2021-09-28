//
//  Matrix4Extensions.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import simd

public typealias vec2 = simd_float2
public typealias vec3 = simd_float3
public typealias vec4 = simd_float4
public typealias matrix2 = simd_float2x2
public typealias matrix3 = simd_float3x3
public typealias matrix4 = simd_float4x4

extension simd_float3{
    
    public func dist(other : simd_float3)->Float{
        return sqrt(pow((other.x-self.x),2) + pow((other.y-self.y),2) + pow((other.z-self.z),2))
    }
}

extension simd_float4{
    public var xyz : vec3{
        return vec3(self.x, self.y, self.z);
    }
}

extension simd_float4x4{
    
    static public func makeScale(x: Float, y: Float, z: Float) -> simd_float4x4{
        let rows = [
            simd_float4(x,0,0,0),
            simd_float4(0,y,0,0),
            simd_float4(0,0,z,0),
            simd_float4(0,0,0, 1)
        ]
        return simd_float4x4(rows: rows)
    }
    
    static public func makeRotation(with axis : vec3, angle : Float) -> simd_float4x4
    {
        let c = cos(angle)
        let s = sin(angle)
        
        var X : vec4 = vec4(0,0,0,0)
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c
        X.y = axis.x * axis.y * (1 - c) - axis.z*s
        X.z = axis.x * axis.z * (1 - c) + axis.y * s
        X.w = 0.0
        
        var Y : vec4 = vec4(0,0,0,0)
        Y.x = axis.x * axis.y * (1 - c) + axis.z * s
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c
        Y.z = axis.y * axis.z * (1 - c) - axis.x * s
        Y.w = 0.0
        
        var Z : vec4 = vec4(0,0,0,0)
        Z.x = axis.x * axis.z * (1 - c) - axis.y * s
        Z.y = axis.y * axis.z * (1 - c) + axis.x * s
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c
        Z.w = 0.0
        
        var W : vec4 = vec4(0,0,0,0)
        W.x = 0.0
        W.y = 0.0
        W.z = 0.0
        W.w = 1.0
        
        let mat = matrix4(X, Y, Z, W)
        return mat
    }
    
    static public func makeRotation(x: Float, y: Float, z: Float) -> simd_float4x4{
        
        let cosx = cos(x)
        let cosy = cos(y)
        let cosz = cos(z)
        let sinx = sin(x)
        let siny = sin(y)
        let sinz = sin(z)
        
        let rows = [
            simd_float4(cosy*cosz,-cosy*sinz,siny,0),
            simd_float4(sinx*siny*cosz+cosx*sinz,-sinx*siny*sinz+cosx*cosz,-sinx*cosy,0),
            simd_float4(-cosx*siny*cosz+sinx*sinz, cosx*siny*sinz + sinx*cosz ,cosx*cosy,0),
            simd_float4(0,0,0, 1)
        ]
        return simd_float4x4(rows: rows)
    
    }
    
    static public func makeTranslation(x: Float, y: Float, z:Float) -> simd_float4x4 {
        let rows = [
            simd_float4(1,0,0,x),
            simd_float4(0,1,0,y),
            simd_float4(0,0,1,z),
            simd_float4(0,0,0,1),
        ]
        let matrix = simd_float4x4(rows: rows)
        
        return matrix
    }
    
    static public func perspectiveProjectionMatrix(angle: Float, aspectRatio : Float, near: Float, far: Float) ->simd_float4x4{
        
        let ys = 1/tanf(angle * 0.5)
        let xs = ys / aspectRatio
        let zs = far / (near-far)
        
        
        var projectionMatrix = simd_float4x4()
        projectionMatrix[0] = simd_float4(xs,0,0,0)
        projectionMatrix[1] = simd_float4(0,ys,0,0)
        projectionMatrix[2] = simd_float4(0,0,zs,-1)
        projectionMatrix[3] = simd_float4(0,0,zs*near,0)
        
        return projectionMatrix
    
    }
    
    static public func orthographicProjectionMatrix(left : Float, right : Float, top : Float, bottom : Float, near: Float, far: Float) ->simd_float4x4{
        
        var projectionMatrix = simd_float4x4()
        projectionMatrix[0] = simd_float4(2.0/(right-left),0,0,-(right+left)/(right-left))
        projectionMatrix[1] = simd_float4(0,2.0/(top-bottom),0,-(top+bottom)/(top-bottom))
        projectionMatrix[2] = simd_float4(0,0,-2.0/(far-near),-(far+near)/(far-near))
        projectionMatrix[3] = simd_float4(0,0,0,1)
        
        return projectionMatrix
        
    }
    
    static func identity() -> simd_float4x4{
        return matrix_identity_float4x4
    }
    
}

extension Float{
    
    static public func degreeToRad(x: Float) -> Float{
        return x*(pi/180.0)
    }
    static public func radToDegree(x:Float) -> Float{
        return x*(180.0/pi)
    }
}

extension Int{
    public func firstNDigits(n : Int) -> Int{
        let digits = String(self).count
        let diff = digits - n
        if diff <= 0{
            return self
        }
        return self/Int(pow(10, Double(diff)))
    }
    
    public func simplifyHash(n : Int) -> Int{
        return abs(self.firstNDigits(n: n))
    }
}

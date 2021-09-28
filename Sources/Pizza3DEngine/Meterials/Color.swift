//
//  Color.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 28/06/21.
//

import Foundation

public struct Color{
    
    static public let blue = vec4(0,0,1,1)
    static public let red = vec4(1,0,0,1)
    static public let green = vec4(0,1,0,1)
    static public let white = vec4(1,1,1,1)
    static public let black = vec4(0,0,0,1)
    static public let orange = vec4(1,0.647,0,1)
    static public let purple = vec4(0.502,0,0.502,1)
    static public let pink = vec4(1, 0.753, 0.796, 1)
    static public let cyan = vec4(0,1,1,1)
    

    
    static public func random() -> vec4{
        let r = Float.random(in: 0...1)
        let g = Float.random(in: 0...1)
        let b = Float.random(in: 0...1)
        let a = Float.random(in: 0...1)
        
        return vec4(r,g,b,a)
    }
    
    static public func random(alpha : Float) -> vec4{
        var color = random()
        color.z = alpha
        return color
    }
    
    static public func to01Scale(color : vec4) -> vec4{
        return color/255.0
    }
    
}

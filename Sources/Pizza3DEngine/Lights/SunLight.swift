//
//  Sunlight.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 25/06/21.
//

import Foundation
import MetalKit

class SunLight : Node, Light{
    public var color: vec3 = vec3(1,1,1)
    public var intensity: Float = 1
    public var lightType: LightType
    public var direction = vec3(0,-1,0)
    
    public override init() {
        lightType = .sun
        super.init()
    }
    
    
    func getShaderLight() -> LightShader{
        var light = LightShader.getDefault()
        light.worldPosition = worldPosition
        light.color = color*intensity
        light.type = Int32(lightType.rawValue)
        light.direction = direction
        
        return light
    }
    
}

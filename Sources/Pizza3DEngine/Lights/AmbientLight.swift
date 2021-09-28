//
//  AmbientLight.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 25/06/21.
//

import Foundation
import MetalKit

class AmbientLight : Node, Light{
    public var color: vec3 = vec3(1,1,1)
    public var intensity: Float = 1
    public var lightType: LightType
    
    public override init() {
        lightType = .ambient
        super.init()
    }
    
    
    func getShaderLight() -> LightShader{
        var light = LightShader.getDefault()
        light.color = color*intensity
        light.type = Int32(lightType.rawValue)
        
        return light
    }
    
}

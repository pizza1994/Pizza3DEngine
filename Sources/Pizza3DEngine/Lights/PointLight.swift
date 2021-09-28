//
//  PointLight.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 21/06/21.
//

import MetalKit

class PointLight : Node, Light{
    
    public var color: vec3 = vec3(1,1,1)
    public var intensity: Float = 1.0
    public var lightType: LightType
    public var range : Float = 25
    public var attenuation : vec3 = vec3(1,0.14,0.07)
    
    public override init() {
        lightType = .point
        super.init()
    }
    
   
    func getShaderLight() -> LightShader{
        var light = LightShader.getDefault()
        light.worldPosition = worldPosition
        light.color = color*intensity
        light.attenuation = attenuation
        light.type = Int32(lightType.rawValue)
        light.range = range
        return light
    }
    
}

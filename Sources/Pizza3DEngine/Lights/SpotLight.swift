//
//  SpotLight.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 25/06/21.
//

import Foundation

import MetalKit

class SpotLight : Node, Light{
    
    public var color: vec3 = vec3(1,1,1)
    public var intensity: Float = 1
    public var lightType: LightType
    public var direction = vec3(0,0,1)
    public var attenuation = vec3(1, 0.14, 0.07)
    public var coneAngle : Float = 45
    public var range : Float = 25
    
    public override init() {
        lightType = .spot
        super.init()
    }
    
    
    func getShaderLight() -> LightShader{
        var light = LightShader.getDefault()
        light.worldPosition = worldPosition
        light.color = color*intensity
        light.type = Int32(lightType.rawValue)
        light.direction = direction
        light.attenuation = attenuation
        light.coneAngle = Float.degreeToRad(x: coneAngle)
        light.range = range
        
        return light
    }
    
}

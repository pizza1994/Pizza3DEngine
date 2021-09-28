//
//  Light.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 21/06/21.
//

public enum LightType : Int{
    case ambient = 0
    case point = 1
    case spot = 2
    case sun = 3
}

public protocol Light{
    func getShaderLight() -> LightShader
    var color : vec3 { get set }
    var intensity : Float {get set}
    var lightType : LightType {get}
    var identifier : Int {get}
}


extension LightShader{
    static func getDefault() -> LightShader{
        
        return LightShader(color: vec3(1,0,0), worldPosition: vec3(0,0,0), attenuation: vec3(0,0,0), direction: vec3(1,0,0), range: 1, coneAngle: 1, type: 0)
    }
}

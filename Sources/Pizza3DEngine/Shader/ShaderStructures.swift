//
//  SharedStructures.swift
//  GoodViewer
//
//  Created by Luca Pitzalis on 07/09/21.
//

import Foundation

public struct Vertex{
    var pos : vec3
    var color : vec4
    var normal : vec3
    var uv : vec2
    var polyCentroid : vec3
    var primitiveType : Int32
}

public struct LightShader{
    var color : vec3
    var worldPosition : vec3
    var attenuation : vec3
    var direction : vec3
    var range : Float32
    var coneAngle : Float32
    var type : Int32
    
}

public struct MaterialShader{
    var ambientColor : vec3
    var diffuseColor : vec3
    var specularColor : vec3
    var shininess : Float32
    var model : Int32
}

public struct FragmentUniforms{
    var numLights : Int32
    var cameraPosition : vec3
}

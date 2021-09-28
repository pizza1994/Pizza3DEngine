//
//  HitResult.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 22/06/21.
//

public enum PickType{
    case vertex
    case edge
    case face
    case poly
    case geometry
}

public struct HitResult {
    public var point : vec3
    public var item : Int
    public var type : PickType
    public var drawableId : Int
}
